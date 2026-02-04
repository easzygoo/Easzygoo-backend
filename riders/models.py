from __future__ import annotations

from django.conf import settings
from django.db import models


class Rider(models.Model):
    class KycStatus(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="rider_profile")

    is_online = models.BooleanField(default=False)
    kyc_status = models.CharField(max_length=20, choices=KycStatus.choices, default=KycStatus.PENDING)

    current_lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    current_lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    def __str__(self) -> str:
        return f"Rider({self.user_id})"
