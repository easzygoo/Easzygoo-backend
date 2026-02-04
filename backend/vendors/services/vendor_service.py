from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal

from django.db.models import Count, Sum
from django.utils import timezone

from orders.models import Order
from vendors.models import Vendor


@dataclass(frozen=True)
class VendorSalesSummary:
    today_total_sales: Decimal
    completed_orders_count: int
    pending_orders_count: int


def get_vendor_for_user(*, user) -> Vendor:
    return Vendor.objects.select_related("user").get(user=user)


def update_vendor_profile(*, user, **fields) -> Vendor:
    vendor = get_vendor_for_user(user=user)

    allowed = {"shop_name", "address", "latitude", "longitude", "is_open"}
    update_fields: list[str] = []

    for key, value in fields.items():
        if key not in allowed:
            continue
        setattr(vendor, key, value)
        update_fields.append(key)

    if update_fields:
        vendor.save(update_fields=update_fields)

    return vendor


def toggle_vendor_open(*, user) -> bool:
    vendor = get_vendor_for_user(user=user)
    vendor.is_open = not vendor.is_open
    vendor.save(update_fields=["is_open"])
    return bool(vendor.is_open)


def get_vendor_dashboard(*, user) -> dict:
    vendor = get_vendor_for_user(user=user)

    now = timezone.localtime(timezone.now())
    start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)

    vendor_orders = Order.objects.filter(vendor=vendor)
    today_orders_qs = vendor_orders.filter(created_at__gte=start_of_day)

    status_counts = dict(
        vendor_orders.values("status").annotate(c=Count("id")).values_list("status", "c")
    )

    today_orders = today_orders_qs.count()
    today_revenue = today_orders_qs.aggregate(total=Sum("total_amount"))["total"] or Decimal("0")

    return {
        "shop_name": vendor.shop_name,
        "is_open": vendor.is_open,
        "placed_orders": int(status_counts.get(Order.Status.PLACED, 0)),
        "accepted_orders": int(status_counts.get(Order.Status.ACCEPTED, 0)),
        "ready_orders": int(status_counts.get(Order.Status.READY, 0)),
        "picked_orders": int(status_counts.get(Order.Status.PICKED, 0)),
        "today_orders": int(today_orders),
        "today_revenue": today_revenue,
    }


def get_vendor_sales_summary(*, user) -> VendorSalesSummary:
    vendor = get_vendor_for_user(user=user)

    now = timezone.localtime(timezone.now())
    start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)

    completed_statuses = [Order.Status.DELIVERED]
    pending_statuses = [Order.Status.PLACED, Order.Status.ACCEPTED, Order.Status.READY]

    completed_orders_count = (
        Order.objects.filter(vendor=vendor, status__in=completed_statuses).count()
    )
    pending_orders_count = Order.objects.filter(vendor=vendor, status__in=pending_statuses).count()

    today_total_sales = (
        Order.objects.filter(
            vendor=vendor,
            status__in=completed_statuses,
            updated_at__gte=start_of_day,
        ).aggregate(total=Sum("total_amount"))["total"]
        or Decimal("0")
    )

    return VendorSalesSummary(
        today_total_sales=today_total_sales,
        completed_orders_count=int(completed_orders_count),
        pending_orders_count=int(pending_orders_count),
    )
