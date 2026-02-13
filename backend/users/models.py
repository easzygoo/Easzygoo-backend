from __future__ import annotations

import uuid

from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models

from .managers import UserManager


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        CUSTOMER = "customer", "Customer"
        VENDOR = "vendor", "Vendor"
        RIDER = "rider", "Rider"
        ADMIN = "admin", "Admin"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=120)
    phone = models.CharField(max_length=20, unique=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.CUSTOMER)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)

    objects = UserManager()

    USERNAME_FIELD = "phone"
    REQUIRED_FIELDS: list[str] = ["name"]

    def __str__(self) -> str:
        return f"{self.phone} ({self.role})"


class Address(models.Model):
    user = models.ForeignKey("users.User", on_delete=models.CASCADE, related_name="addresses")

    label = models.CharField(max_length=60, blank=True, default="")
    receiver_name = models.CharField(max_length=120, blank=True, default="")
    receiver_phone = models.CharField(max_length=20, blank=True, default="")

    line1 = models.CharField(max_length=255)
    line2 = models.CharField(max_length=255, blank=True, default="")
    landmark = models.CharField(max_length=255, blank=True, default="")
    city = models.CharField(max_length=120)
    state = models.CharField(max_length=120)
    pincode = models.CharField(max_length=12)

    is_default = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"Address({self.id})"
