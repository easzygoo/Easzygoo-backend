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


class VendorKyc(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    vendor = models.OneToOneField("vendors.Vendor", on_delete=models.CASCADE, related_name="kyc")

    id_front_path = models.CharField(max_length=500, blank=True)
    id_back_path = models.CharField(max_length=500, blank=True)
    shop_license_path = models.CharField(max_length=500, blank=True)
    selfie_path = models.CharField(max_length=500, blank=True)

    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"VendorKYC({self.vendor_id}, {self.status})"
