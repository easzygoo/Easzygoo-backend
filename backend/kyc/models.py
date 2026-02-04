from __future__ import annotations

from django.db import models


# Legacy helper kept for backwards-compatible migrations.
# (The app no longer stores KYC files in Django; it stores Supabase object paths.)
def kyc_upload_path(instance, filename: str) -> str:  # pragma: no cover
    return f"kyc/{instance.rider_id}/{filename}"


class RiderKyc(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    rider = models.OneToOneField("riders.Rider", on_delete=models.CASCADE, related_name="kyc")

    # Supabase Storage object paths (bucket is private; serve via signed URLs only).
    aadhaar_front_path = models.CharField(max_length=500, blank=True)
    aadhaar_back_path = models.CharField(max_length=500, blank=True)
    pan_path = models.CharField(max_length=500, blank=True)
    license_path = models.CharField(max_length=500, blank=True)
    rc_path = models.CharField(max_length=500, blank=True)
    selfie_path = models.CharField(max_length=500, blank=True)

    bank_account = models.CharField(max_length=32)
    ifsc = models.CharField(max_length=16)

    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"KYC({self.rider_id}, {self.status})"
