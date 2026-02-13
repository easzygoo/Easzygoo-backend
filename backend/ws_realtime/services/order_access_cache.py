from __future__ import annotations

from typing import Any

from django.core.cache import cache


def _key(order_id: str) -> str:
    return f"order_access:{order_id}"


def set_order_access(
    *,
    order_id: str,
    customer_id: str,
    vendor_user_id: str,
    rider_user_id: str | None,
    ttl_seconds: int = 60 * 60 * 24,
) -> None:
    cache.set(
        _key(order_id),
        {
            "customer_id": customer_id,
            "vendor_user_id": vendor_user_id,
            "rider_user_id": rider_user_id,
        },
        timeout=ttl_seconds,
    )


def get_order_access(*, order_id: str) -> dict[str, Any] | None:
    value = cache.get(_key(order_id))
    if not value:
        return None
    if not isinstance(value, dict):
        return None
    return value
