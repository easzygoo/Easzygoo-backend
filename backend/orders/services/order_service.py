from __future__ import annotations

from decimal import Decimal

from django.db import transaction
from django.db.models import Sum

from orders.models import Order
from ws_realtime.services.order_events import emit_order_event
from riders.models import Rider

from .order_access_service import cache_order_access_from_instance


ACTIVE_STATUSES = {
    Order.Status.ACCEPTED,
    Order.Status.READY,
    Order.Status.PICKED,
}


def get_assigned_active_order(rider: Rider) -> Order | None:
    return (
        Order.objects.filter(rider=rider, status__in=list(ACTIVE_STATUSES))
        .order_by("-updated_at")
        .first()
    )


@transaction.atomic
def accept_order(*, rider: Rider, order: Order) -> Order:
    if order.rider_id and order.rider_id != rider.id:
        raise ValueError("Order is already assigned to another rider")

    if order.status != Order.Status.PLACED:
        raise ValueError("Only placed orders can be accepted")

    order.rider = rider
    order.status = Order.Status.ACCEPTED
    order.save(update_fields=["rider", "status", "updated_at"])

    # Ensure order.rider.user is available for caching.
    order.rider = rider
    cache_order_access_from_instance(order=order)

    emit_order_event(
        order_id=str(order.id),
        name="order_accepted",
        payload={
            "status": order.status,
            "rider_id": str(rider.id),
        },
    )
    return order


@transaction.atomic
def mark_picked(*, rider: Rider, order: Order) -> Order:
    if order.rider_id != rider.id:
        raise ValueError("Order not assigned to this rider")
    if order.status not in {Order.Status.ACCEPTED, Order.Status.READY}:
        raise ValueError("Order must be accepted/ready before it can be picked")

    order.status = Order.Status.PICKED
    order.save(update_fields=["status", "updated_at"])

    order.rider = rider
    cache_order_access_from_instance(order=order)

    emit_order_event(
        order_id=str(order.id),
        name="order_picked",
        payload={
            "status": order.status,
            "rider_id": str(rider.id),
        },
    )
    return order


@transaction.atomic
def mark_delivered(*, rider: Rider, order: Order) -> Order:
    if order.rider_id != rider.id:
        raise ValueError("Order not assigned to this rider")
    if order.status != Order.Status.PICKED:
        raise ValueError("Order must be picked before it can be delivered")

    order.status = Order.Status.DELIVERED
    order.save(update_fields=["status", "updated_at"])

    order.rider = rider
    cache_order_access_from_instance(order=order)

    emit_order_event(
        order_id=str(order.id),
        name="order_delivered",
        payload={
            "status": order.status,
            "rider_id": str(rider.id),
        },
    )
    return order


def earnings_summary(rider: Rider) -> dict:
    delivered = Order.objects.filter(rider=rider, status=Order.Status.DELIVERED)
    count = delivered.count()
    total = delivered.aggregate(total=Sum("total_amount"))["total"] or Decimal("0")
    return {
        "delivered_orders": count,
        "total_delivered_amount": total,
    }
