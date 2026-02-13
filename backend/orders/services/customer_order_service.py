from __future__ import annotations

from orders.models import Order


def list_customer_orders(*, customer):
    return Order.objects.filter(customer=customer).order_by("-created_at")


def get_customer_order(*, customer, order_id) -> Order:
    return Order.objects.get(customer=customer, pk=order_id)
