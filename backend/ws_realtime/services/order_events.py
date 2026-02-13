from __future__ import annotations

from typing import Any

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.utils import timezone


def emit_order_event(*, order_id: str, name: str, payload: dict[str, Any] | None = None) -> None:
    """Emit an order-scoped realtime event.

    Service-layer emitter (never call from views): publishes to the
    `order_<order_id>` WebSocket group through the configured channel layer.

    If the channel layer is unavailable (misconfig/local), this is a no-op.
    """

    channel_layer = get_channel_layer()
    if channel_layer is None:
        return

    group_name = f"order_{order_id}"

    async_to_sync(channel_layer.group_send)(
        group_name,
        {
            "type": "order.event",
            "name": name,
            "order_id": order_id,
            "payload": payload or {},
            "server_time": timezone.now().isoformat(),
        },
    )
