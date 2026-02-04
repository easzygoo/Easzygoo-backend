from __future__ import annotations

import math
from dataclasses import dataclass
from decimal import Decimal
from typing import Iterable

from django.db import transaction

from orders.models import Order
from riders.models import Rider


EARTH_RADIUS_KM = 6371.0


@dataclass(frozen=True)
class CandidateRider:
    rider: Rider
    distance_km: float


def haversine_km(*, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Compute great-circle distance in kilometers using the Haversine formula.

    Pure function (unit-test friendly).
    """

    # Convert degrees -> radians
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)

    a = math.sin(d_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return EARTH_RADIUS_KM * c


def _to_float(value: float | Decimal) -> float:
    return float(value)


def _iter_candidates(*, vendor_lat: float, vendor_lng: float, riders: Iterable[Rider]) -> list[CandidateRider]:
    candidates: list[CandidateRider] = []

    for rider in riders:
        if rider.current_lat is None or rider.current_lng is None:
            continue

        distance = haversine_km(
            lat1=vendor_lat,
            lon1=vendor_lng,
            lat2=_to_float(rider.current_lat),
            lon2=_to_float(rider.current_lng),
        )
        candidates.append(CandidateRider(rider=rider, distance_km=distance))

    candidates.sort(key=lambda c: c.distance_km)
    return candidates


@transaction.atomic
def assign_rider_to_order(order: Order) -> Order:
    """Assign the nearest available rider to an order (best-effort).

    Rules:
    - Rider must be online: Rider.is_online=True
    - Rider must be KYC approved: Rider.kyc_status=APPROVED
    - Rider must have a current location set

    If no rider found:
    - Leave order.rider as-is (typically null)

    Notes:
    - This is intentionally simple (no PostGIS).
    - For concurrency/scale, later you’ll want row-level locking or a queue.
    """

    # If already assigned, do nothing.
    if order.rider_id:
        return order

    vendor = order.vendor
    vendor_lat = vendor.latitude
    vendor_lng = vendor.longitude

    available = Rider.objects.select_related("user").filter(
        is_online=True,
        kyc_status=Rider.KycStatus.APPROVED,
        current_lat__isnull=False,
        current_lng__isnull=False,
    )

    candidates = _iter_candidates(
        vendor_lat=_to_float(vendor_lat),
        vendor_lng=_to_float(vendor_lng),
        riders=available,
    )

    if not candidates:
        return order

    nearest = candidates[0].rider
    order.rider = nearest
    # Keep status as PLACED but assigned.
    order.status = Order.Status.PLACED
    order.save(update_fields=["rider", "status", "updated_at"])
    return order
