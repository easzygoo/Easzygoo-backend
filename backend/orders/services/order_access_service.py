from __future__ import annotations

from django.core.exceptions import ObjectDoesNotExist

from orders.models import Order
from ws_realtime.services.order_access_cache import get_order_access, set_order_access


def get_or_cache_order_access(*, order_id: str) -> dict:
    """Return order access metadata, using cache when available.

    This keeps WebSocket consumers thin and avoids DB hits in steady-state.
    """

    cached = get_order_access(order_id=order_id)
    if cached is not None:
        return cached

    order = (
        Order.objects.select_related("vendor__user", "rider__user")
        .only("id", "customer_id", "vendor__user_id", "rider__user_id")
        .get(pk=order_id)
    )

    rider_user_id = None
    if order.rider_id and order.rider:
        rider_user_id = str(order.rider.user_id)

    vendor_user_id = str(order.vendor.user_id) if getattr(order, "vendor", None) else ""

    access = {
        "customer_id": str(order.customer_id),
        "vendor_user_id": vendor_user_id,
        "rider_user_id": rider_user_id,
    }

    set_order_access(
        order_id=str(order.id),
        customer_id=access["customer_id"],
        vendor_user_id=access["vendor_user_id"],
        rider_user_id=access["rider_user_id"],
    )

    return access


def cache_order_access_from_instance(*, order: Order) -> None:
    """Cache access metadata from an already-available order instance."""

    rider_user_id = None
    if getattr(order, "rider_id", None) and getattr(order, "rider", None):
        rider_user_id = str(order.rider.user_id)

    vendor_user_id = str(order.vendor.user_id) if getattr(order, "vendor", None) else ""

    if not vendor_user_id:
        # We require vendor_user_id; if it's not loaded, don't risk caching wrong.
        return

    set_order_access(
        order_id=str(order.id),
        customer_id=str(order.customer_id),
        vendor_user_id=vendor_user_id,
        rider_user_id=rider_user_id,
    )
