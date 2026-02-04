from __future__ import annotations

from django.db import transaction

from riders.models import Rider
from users.models import User


@transaction.atomic
def get_or_create_rider_for_user(user: User) -> Rider:
    rider, _ = Rider.objects.get_or_create(user=user)
    return rider


@transaction.atomic
def toggle_online(rider: Rider, is_online: bool) -> Rider:
    rider.is_online = bool(is_online)
    rider.save(update_fields=["is_online"])
    return rider


@transaction.atomic
def update_location(rider: Rider, lat, lng) -> Rider:
    rider.current_lat = lat
    rider.current_lng = lng
    rider.save(update_fields=["current_lat", "current_lng"])
    return rider
