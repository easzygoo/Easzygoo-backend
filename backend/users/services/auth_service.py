from __future__ import annotations

from dataclasses import dataclass

from django.db import transaction
from rest_framework_simplejwt.tokens import RefreshToken

from users.models import User


MOCK_OTP = "0000"


@dataclass(frozen=True)
class LoginResult:
    user: User
    access: str
    refresh: str


def verify_mock_otp(phone: str, otp: str) -> bool:
    return otp.strip() == MOCK_OTP


@transaction.atomic
def login_with_phone(phone: str, otp: str, *, name_if_create: str | None = None, role_if_create: str = User.Role.RIDER) -> LoginResult:
    phone = phone.strip()
    otp = otp.strip()

    if not verify_mock_otp(phone, otp):
        raise ValueError("Invalid OTP")

    user, created = User.objects.get_or_create(
        phone=phone,
        defaults={
            "name": (name_if_create or "Rider"),
            "role": role_if_create,
            "is_active": True,
        },
    )

    if not user.is_active:
        raise ValueError("User is inactive")

    # Issue JWT
    refresh = RefreshToken.for_user(user)
    return LoginResult(user=user, access=str(refresh.access_token), refresh=str(refresh))
