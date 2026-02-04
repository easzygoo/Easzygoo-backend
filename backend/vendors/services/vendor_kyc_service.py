from __future__ import annotations

from django.db import transaction
from rest_framework.exceptions import APIException, PermissionDenied, ValidationError

from kyc.services.kyc_storage_service import (
    KycFileValidationError,
    KycStorageError,
    delete_file,
    upload_file,
)
from users.models import User
from vendors.models import VendorKyc
from vendors.services.vendor_service import get_vendor_for_user


class VendorKycUpstreamError(APIException):
    status_code = 502
    default_detail = "Verification storage is temporarily unavailable."
    default_code = "vendor_verification_storage_unavailable"


ALLOWED_VENDOR_DOCUMENT_TYPES: dict[str, str] = {
    "id_front": "id_front_path",
    "id_back": "id_back_path",
    "shop_license": "shop_license_path",
    "selfie": "selfie_path",
}


def get_vendor_kyc_status_for_user(user: User) -> dict:
    if user.role != User.Role.VENDOR:
        raise PermissionDenied("Only vendors can access verification status")

    vendor = get_vendor_for_user(user=user)
    kyc = VendorKyc.objects.filter(vendor=vendor).first()
    if not kyc:
        return {"submitted": False, "status": None}

    return {"submitted": True, "status": kyc.status}


@transaction.atomic
def submit_vendor_kyc_for_user(*, user: User, payload: dict) -> VendorKyc:
    if user.role != User.Role.VENDOR:
        raise PermissionDenied("Only vendors can submit verification")

    vendor = get_vendor_for_user(user=user)

    uploaded_paths: dict[str, str] = {}

    try:
        for doc_type, model_field in ALLOWED_VENDOR_DOCUMENT_TYPES.items():
            file_obj = payload.get(doc_type)
            if file_obj is None:
                raise ValidationError({doc_type: "This file is required."})
            uploaded_paths[model_field] = upload_file(file_obj, str(vendor.id), f"vendor_{doc_type}")
    except KycFileValidationError as exc:
        raise ValidationError(str(exc)) from exc
    except KycStorageError as exc:
        raise VendorKycUpstreamError() from exc
    except ValidationError:
        raise
    except Exception as exc:  # noqa: BLE001
        raise VendorKycUpstreamError() from exc

    existing = VendorKyc.objects.filter(vendor=vendor).first()
    old_paths: list[str] = []
    if existing:
        for field in ALLOWED_VENDOR_DOCUMENT_TYPES.values():
            value = getattr(existing, field, "")
            if value:
                old_paths.append(value)

    defaults = {
        **uploaded_paths,
        "status": VendorKyc.Status.PENDING,
    }

    obj, _ = VendorKyc.objects.update_or_create(vendor=vendor, defaults=defaults)

    for path in old_paths:
        try:
            delete_file(path)
        except KycStorageError:
            pass

    return obj
