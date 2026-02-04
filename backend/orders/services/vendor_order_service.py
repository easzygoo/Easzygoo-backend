from __future__ import annotations

from django.core.exceptions import ObjectDoesNotExist

from orders.models import Order
from vendors.services.vendor_service import get_vendor_for_user


def list_vendor_orders(*, user, status: str | None = None):
    vendor = get_vendor_for_user(user=user)
    qs = Order.objects.filter(vendor=vendor).order_by("-created_at")
    if status:
        qs = qs.filter(status=status)
    return qs


def get_vendor_order(*, user, order_id) -> Order:
    vendor = get_vendor_for_user(user=user)
    return Order.objects.get(vendor=vendor, pk=order_id)


def mark_vendor_order_ready(*, user, order_id) -> Order:
    order = get_vendor_order(user=user, order_id=order_id)

    if order.status not in {Order.Status.PLACED, Order.Status.ACCEPTED}:
        raise ValueError("Order must be placed/accepted before it can be marked ready")

    order.status = Order.Status.READY
    order.save(update_fields=["status", "updated_at"])
    return order


def cancel_vendor_order(*, user, order_id) -> Order:
    order = get_vendor_order(user=user, order_id=order_id)

    if order.status in {Order.Status.PICKED, Order.Status.DELIVERED}:
        raise ValueError("Picked/delivered orders cannot be cancelled")

    order.status = Order.Status.CANCELLED
    order.save(update_fields=["status", "updated_at"])
    return order


def accept_vendor_order(*, user, order_id) -> Order:
    order = get_vendor_order(user=user, order_id=order_id)

    if order.status != Order.Status.PLACED:
        raise ValueError("Only placed orders can be accepted")

    order.status = Order.Status.ACCEPTED
    order.save(update_fields=["status", "updated_at"])
    return order


def reject_vendor_order(*, user, order_id) -> Order:
    order = get_vendor_order(user=user, order_id=order_id)

    if order.status in {Order.Status.PICKED, Order.Status.DELIVERED}:
        raise ValueError("Picked/delivered orders cannot be rejected")
    if order.status == Order.Status.CANCELLED:
        raise ValueError("Order is already cancelled")

    order.status = Order.Status.CANCELLED
    order.save(update_fields=["status", "updated_at"])
    return order
