from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass
from decimal import Decimal

from django.db import transaction

from orders.models import Order, OrderItem
from products.models import Product
from users.models import User
from users.models import Address
from vendors.models import Vendor

from .rider_assignment_service import assign_rider_to_order
from .order_access_service import cache_order_access_from_instance


@dataclass(frozen=True)
class OrderItemInput:
    product_id: str
    quantity: int


@transaction.atomic
def place_order_for_customer(
    *,
    customer: User,
    vendor: Vendor,
    items: Iterable[OrderItemInput],
    delivery_address: Address | None = None,
    payment_method: str = Order.PaymentMethod.COD,
) -> Order:
    """Create an order and assign a rider (best-effort) inside one transaction."""

    items_list = list(items)
    if not items_list:
        raise ValueError("Order must contain at least one item")

    if not vendor.is_open:
        raise ValueError("Vendor is currently closed")

    product_ids = [item.product_id for item in items_list]

    products_qs = Product.objects.select_for_update().filter(
        id__in=product_ids,
        vendor=vendor,
        is_active=True,
    )
    products_by_id = {str(p.id): p for p in products_qs}

    missing = [pid for pid in product_ids if str(pid) not in products_by_id]
    if missing:
        raise ValueError("One or more products are invalid or unavailable")

    order_items: list[OrderItem] = []
    total_amount = Decimal("0")

    for item in items_list:
        if item.quantity <= 0:
            raise ValueError("Quantity must be >= 1")

        product = products_by_id[str(item.product_id)]
        if product.stock < item.quantity:
            raise ValueError(f"Insufficient stock for product {product.id}")

        price = product.price
        line_total = price * item.quantity
        total_amount += line_total

        order_items.append(
            OrderItem(
                product=product,
                quantity=item.quantity,
                price=price,
            )
        )

    order = Order.objects.create(
        customer=customer,
        vendor=vendor,
        delivery_address=delivery_address,
        status=Order.Status.PLACED,
        total_amount=total_amount,
        payment_method=payment_method,
        payment_status=Order.PaymentStatus.PENDING,
    )

    for oi in order_items:
        oi.order = order

    OrderItem.objects.bulk_create(order_items)

    # Reduce stock while holding locks.
    for item in items_list:
        product = products_by_id[str(item.product_id)]
        product.stock -= item.quantity
        product.save(update_fields=["stock"])

    # Best-effort assignment (leaves order.rider null if none).
    assign_rider_to_order(order)

    # Cache access metadata for websocket authorization (cache-first; avoids consumer DB hits).
    # Ensure vendor.user is available (Vendor instance is already present here).
    order.vendor = vendor
    cache_order_access_from_instance(order=order)

    return order
