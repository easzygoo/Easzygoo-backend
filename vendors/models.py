from __future__ import annotations

from django.conf import settings
from django.db import models


class Vendor(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="vendor_profile")

    shop_name = models.CharField(max_length=160)
    address = models.TextField()
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    is_open = models.BooleanField(default=True)

    def __str__(self) -> str:
        return self.shop_name
