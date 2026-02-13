from __future__ import annotations

import time
from typing import Any

import logging
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.utils import timezone


logger = logging.getLogger("realtime")


class LocationConsumer(AsyncJsonWebsocketConsumer):
    """Rider -> Order group live location updates.

    Thin transport consumer:
    - requires authenticated rider
    - validates payload schema
    - throttles updates (>= 1s)
    - broadcasts to `order_<order_id>` group via Redis channel layer
    """

    MIN_INTERVAL_SECONDS = 1.0

    def __init__(self, *args: Any, **kwargs: Any):
        super().__init__(*args, **kwargs)
        self._last_emit_at: float | None = None

    async def connect(self):
        user = self.scope.get("user")

        if not user or not getattr(user, "is_authenticated", False):
            await self.close(code=4401)  # Unauthorized
            return

        if getattr(user, "role", None) != "rider":
            await self.close(code=4403)  # Forbidden
            return

        await self.accept()

        logger.info(
            "ws_connected",
            extra={
                "event": "ws_connected",
                "user_id": str(getattr(user, "id", "")),
                "role": getattr(user, "role", None),
            },
        )

    async def receive_json(self, content: Any, **kwargs):
        if not isinstance(content, dict):
            return

        now_mono = time.monotonic()
        if self._last_emit_at is not None and (now_mono - self._last_emit_at) < self.MIN_INTERVAL_SECONDS:
            return

        order_id = (content.get("order_id") or "").strip()
        if not order_id:
            return

        lat = content.get("lat")
        lng = content.get("lng")

        try:
            lat_f = float(lat)
            lng_f = float(lng)
        except Exception:
            return

        if not (-90.0 <= lat_f <= 90.0 and -180.0 <= lng_f <= 180.0):
            return

        self._last_emit_at = now_mono

        user = self.scope.get("user")
        rider_id = str(getattr(user, "id", ""))

        group_name = f"order_{order_id}"

        await self.channel_layer.group_send(
            group_name,
            {
                "type": "location.update",
                "order_id": order_id,
                "lat": lat_f,
                "lng": lng_f,
                "rider_id": rider_id,
                "server_time": timezone.now().isoformat(),
            },
        )

    async def disconnect(self, close_code):
        # No groups are joined here (publisher-only), so nothing to clean up.
        user = self.scope.get("user")
        logger.info(
            "ws_disconnected",
            extra={
                "event": "ws_disconnected",
                "user_id": str(getattr(user, "id", "")) if user else None,
                "role": getattr(user, "role", None) if user else None,
            },
        )
        return
