from __future__ import annotations

from dataclasses import dataclass

from django.db import transaction
from rest_framework.exceptions import APIException, NotFound, PermissionDenied, ValidationError

from kyc.models import RiderKyc
from riders.models import Rider
from riders.services.rider_service import get_or_create_rider_for_user
from users.models import User

from .kyc_storage_service import (
    KycFileValidationError,
    KycStorageError,
    delete_file,
    generate_signed_url,
    upload_file,
)


class KycUpstreamError(APIException):
    status_code = 502
    default_detail = "KYC storage is temporarily unavailable."
    default_code = "kyc_storage_unavailable"


ALLOWED_DOCUMENT_TYPES: dict[str, str] = {
    "aadhaar_front": "aadhaar_front_path",
    "aadhaar_back": "aadhaar_back_path",
    "pan": "pan_path",
    "license": "license_path",
    "rc": "rc_path",
    "selfie": "selfie_path",
}


@dataclass(frozen=True)
class SignedUrlResult:
    url: str


@transaction.atomic
def submit_kyc(*, rider: Rider, payload: dict) -> RiderKyc:
    # Upload all docs first (external side effects). If any upload fails,
    # best-effort cleanup already uploaded objects.
    uploaded_paths: dict[str, str] = {}

    try:
        for doc_type, model_field in ALLOWED_DOCUMENT_TYPES.items():
            file_obj = payload.get(doc_type)
            if file_obj is None:
                raise ValidationError({doc_type: "This file is required."})
            uploaded_paths[model_field] = upload_file(file_obj, str(rider.id), doc_type)
    except KycFileValidationError as exc:
        # User-provided invalid upload.
        raise ValidationError(str(exc)) from exc
    except KycStorageError as exc:
        # Storage connectivity/auth/bucket issues.
        raise KycUpstreamError() from exc
    except ValidationError:
        raise
    except Exception as exc:  # noqa: BLE001
        raise KycUpstreamError() from exc

    existing = RiderKyc.objects.filter(rider=rider).first()
    old_paths: list[str] = []
    if existing:
        for field in ALLOWED_DOCUMENT_TYPES.values():
            value = getattr(existing, field, "")
            if value:
                old_paths.append(value)

    defaults = {
        **uploaded_paths,
        "bank_account": payload["bank_account"],
        "ifsc": payload["ifsc"],
        "status": RiderKyc.Status.PENDING,
    }

    obj, _ = RiderKyc.objects.update_or_create(rider=rider, defaults=defaults)

    # If DB update succeeded, best-effort cleanup of old objects.
    for path in old_paths:
        try:
            delete_file(path)
        except KycStorageError:
            # Ignore cleanup failures; old files may remain until a retention job.
            pass

    # Mirror status onto Rider for quick checks.
    rider.kyc_status = Rider.KycStatus.PENDING
    rider.save(update_fields=["kyc_status"])

    return obj


def get_kyc_status_for_user(user: User) -> dict:
    if user.role != User.Role.RIDER:
        raise PermissionDenied("Only riders can access KYC status")
    rider = get_or_create_rider_for_user(user)
    return get_kyc_status(rider)


@transaction.atomic
def submit_kyc_for_user(*, user: User, payload: dict) -> RiderKyc:
    if user.role != User.Role.RIDER:
        raise PermissionDenied("Only riders can submit KYC")
    rider = get_or_create_rider_for_user(user)
    return submit_kyc(rider=rider, payload=payload)


def generate_signed_document_url(*, request_user: User, document_type: str, rider_user_id: str | None = None) -> SignedUrlResult:
    doc_type = (document_type or "").strip().lower()
    if doc_type not in ALLOWED_DOCUMENT_TYPES:
        raise ValidationError({"document_type": "Invalid document type"})

    # Resolve which rider's document can be viewed.
    if request_user.role == User.Role.RIDER:
        rider = get_or_create_rider_for_user(request_user)
    elif request_user.role == User.Role.ADMIN:
        if not rider_user_id:
            raise ValidationError({"rider_user_id": "This query parameter is required for admin viewing"})
        try:
            target_user = User.objects.get(id=rider_user_id)
        except User.DoesNotExist as exc:
            raise NotFound("Rider user not found") from exc

        rider = Rider.objects.filter(user=target_user).first()
        if not rider:
            raise NotFound("Rider profile not found")
    else:
        raise PermissionDenied("Not allowed")

    kyc = RiderKyc.objects.filter(rider=rider).first()
    if not kyc:
        raise NotFound("KYC not submitted")

    path_field = ALLOWED_DOCUMENT_TYPES[doc_type]
    storage_path = getattr(kyc, path_field, "")
    if not storage_path:
        raise NotFound("Document not found")

    try:
        url = generate_signed_url(storage_path, expires_in_seconds=300)
    except KycStorageError as exc:
        raise KycUpstreamError() from exc

    return SignedUrlResult(url=url)


def get_kyc_status(rider: Rider) -> dict:
    kyc = getattr(rider, "kyc", None)
    if not kyc:
        return {"submitted": False, "status": None}
    return {"submitted": True, "status": kyc.status}
