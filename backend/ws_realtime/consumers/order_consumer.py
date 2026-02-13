from __future__ import annotations

import logging
from typing import Any

from channels.generic.websocket import AsyncJsonWebsocketConsumer

from orders.services.order_access_service import get_or_cache_order_access


logger = logging.getLogger("realtime")


class OrderConsumer(AsyncJsonWebsocketConsumer):
    """Order-scoped realtime subscription consumer.

    Thin transport consumer:
    - requires authenticated user
    - joins `order_<order_id>` group
    - forwards group events to client

    Ownership/role enforcement is added in a later stage.
    """

    async def connect(self):
        user = self.scope.get("user")
        if not user or not getattr(user, "is_authenticated", False):
            await self.close(code=4401)
            return

        order_id = (self.scope.get("url_route", {}).get("kwargs", {}).get("order_id") or "").strip()
        if not order_id:
            await self.close(code=4400)
            return

        self.order_id = order_id
        self.group_name = f"order_{order_id}"

        # Ownership / role-based authorization (cache-first).
        try:
            access = await self._get_access(order_id)
        except Exception:
            await self.close(code=4400)
            return

        role = getattr(user, "role", None)
        user_id = str(getattr(user, "id", ""))
        allowed = False

        if role == "customer":
            allowed = user_id == str(access.get("customer_id"))
        elif role == "vendor":
            allowed = user_id == str(access.get("vendor_user_id"))
        elif role == "rider":
            allowed = user_id == str(access.get("rider_user_id"))

        if not allowed:
            logger.info(
                "ws_forbidden",
                extra={
                    "event": "ws_forbidden",
                    "user_id": user_id,
                    "role": role,
                    "order_id": order_id,
                },
            )
            await self.close(code=4403)
            return

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

        logger.info(
            "ws_connected",
            extra={
                "event": "ws_connected",
                "user_id": str(getattr(user, "id", "")),
                "role": getattr(user, "role", None),
                "order_id": order_id,
            },
        )

    async def _get_access(self, order_id: str) -> dict:
        # Run cache/db access lookup in a thread to avoid blocking the event loop.
        from asgiref.sync import sync_to_async

        return await sync_to_async(get_or_cache_order_access)(order_id=order_id)

    async def disconnect(self, close_code):
        group = getattr(self, "group_name", None)
        if group:
            await self.channel_layer.group_discard(group, self.channel_name)

        user = self.scope.get("user")
        logger.info(
            "ws_disconnected",
            extra={
                "event": "ws_disconnected",
                "user_id": str(getattr(user, "id", "")) if user else None,
                "role": getattr(user, "role", None) if user else None,
                "order_id": getattr(self, "order_id", None),
            },
        )

    async def receive_json(self, content: Any, **kwargs):
        # Subscriber is read-only for now.
        return

    async def location_update(self, event: dict):
        await self.send_json({
            "type": "location_update",
            "order_id": event.get("order_id"),
            "lat": event.get("lat"),
            "lng": event.get("lng"),
            "rider_id": event.get("rider_id"),
            "server_time": event.get("server_time"),
        })

    async def order_event(self, event: dict):
        # Generic order event channel for future service-layer events.
        await self.send_json({
            "type": "order_event",
            "name": event.get("name"),
            "order_id": event.get("order_id"),
            "payload": event.get("payload"),
            "server_time": event.get("server_time"),
        })
