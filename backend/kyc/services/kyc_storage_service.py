from __future__ import annotations

import os
import time
from dataclasses import dataclass
from typing import IO, Any, Optional, Protocol, Union

from supabase import Client, create_client


MAX_KYC_FILE_SIZE_BYTES = 5 * 1024 * 1024
ALLOWED_IMAGE_CONTENT_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
}


class KycStorageError(Exception):
    """Raised when Supabase Storage operations fail."""


class KycFileValidationError(ValueError):
    """Raised when an uploaded KYC file is invalid (type/size/etc)."""


class _UploadedFileLike(Protocol):
    # DRF/Django uploaded files typically provide these
    size: int
    content_type: str | None
    name: str

    def read(self, size: int = -1) -> bytes:  # pragma: no cover
        ...


UploadedFile = Union[_UploadedFileLike, IO[bytes]]


@dataclass(frozen=True)
class UploadResult:
    path: str


def _get_required_env(name: str) -> str:
    value = (os.getenv(name) or "").strip()
    if not value:
        raise KycStorageError(f"Missing required environment variable: {name}")
    return value


def _supabase_client() -> Client:
    url = _get_required_env("SUPABASE_URL")
    key = _get_required_env("SUPABASE_SERVICE_ROLE_KEY")
    return create_client(url, key)


def _bucket_name() -> str:
    return os.getenv("SUPABASE_BUCKET_NAME", "kyc-documents").strip() or "kyc-documents"


def _now_ms() -> int:
    return int(time.time() * 1000)


def _validate_image_upload(file: UploadedFile) -> tuple[bytes, str]:
    """Validate file is an image and <= 5MB, returning (content_bytes, content_type)."""

    content_type = getattr(file, "content_type", None) or ""
    size = getattr(file, "size", None)

    if size is None:
        # Try to read and infer size
        content = file.read()
        if len(content) > MAX_KYC_FILE_SIZE_BYTES:
            raise KycFileValidationError("File too large (max 5MB)")
    else:
        if int(size) <= 0:
            raise KycFileValidationError("Empty file")
        if int(size) > MAX_KYC_FILE_SIZE_BYTES:
            raise KycFileValidationError("File too large (max 5MB)")
        content = file.read()

    # Reset not possible for all file types; callers should not reuse the stream.

    normalized = content_type.lower().strip()
    if not normalized:
        raise KycFileValidationError("Missing content type")

    if normalized not in ALLOWED_IMAGE_CONTENT_TYPES:
        raise KycFileValidationError("Invalid file type (only JPEG/PNG images allowed)")

    if not content:
        raise KycFileValidationError("Empty file")

    if normalized in {"image/jpg", "image/jpeg"}:
        return content, "image/jpeg"
    return content, normalized


def upload_file(file: UploadedFile, rider_id: str, document_type: str) -> str:
    """Upload a KYC document image to Supabase Storage.

    Path structure:
      kyc/<rider_id>/<document_type>_<timestamp>.jpg

    Returns:
      The private storage path (to store in DB). Never return this path to clients.
    """

    if not rider_id or not str(rider_id).strip():
        raise KycFileValidationError("Missing rider_id")
    if not document_type or not str(document_type).strip():
        raise KycFileValidationError("Missing document_type")

    content, content_type = _validate_image_upload(file)

    safe_rider_id = str(rider_id).strip()
    safe_doc_type = str(document_type).strip().lower()
    ext = "jpg" if content_type == "image/jpeg" else "png"
    object_path = f"kyc/{safe_rider_id}/{safe_doc_type}_{_now_ms()}.{ext}"

    client = _supabase_client()
    bucket = _bucket_name()

    try:
        # Official client expects bytes for small uploads.
        res: Any = client.storage.from_(bucket).upload(
            path=object_path,
            file=content,
            file_options={
                "content-type": content_type,
                "cache-control": "3600",
                "upsert": "false",
            },
        )

        # Some versions return dict-like; others return a response object.
        if isinstance(res, dict) and res.get("error"):
            raise KycStorageError(str(res["error"]))

        return object_path
    except KycFileValidationError:
        raise
    except Exception as exc:  # noqa: BLE001
        raise KycStorageError("Failed to upload KYC document") from exc


def generate_signed_url(file_path: str, *, expires_in_seconds: int = 300) -> str:
    """Generate a time-limited signed URL for a private object.

    - Default expiry: 5 minutes.
    - Returns the signed URL only.
    """

    path = (file_path or "").strip()
    if not path:
        raise KycStorageError("Missing file_path")

    client = _supabase_client()
    bucket = _bucket_name()

    try:
        res: Any = client.storage.from_(bucket).create_signed_url(path, expires_in_seconds)

        if isinstance(res, dict):
            if res.get("error"):
                raise KycStorageError(str(res["error"]))
            url = res.get("signedURL") or res.get("signedUrl") or res.get("signed_url")
            if not url:
                raise KycStorageError("Failed to generate signed URL")
            return str(url)

        # Fallback: try attribute access
        url = getattr(res, "signed_url", None) or getattr(res, "signedURL", None)
        if not url:
            raise KycStorageError("Failed to generate signed URL")
        return str(url)
    except Exception as exc:  # noqa: BLE001
        raise KycStorageError("Failed to generate signed URL") from exc


def delete_file(file_path: str) -> None:
    """Delete an object from Supabase Storage (best-effort helper)."""

    path = (file_path or "").strip()
    if not path:
        return

    client = _supabase_client()
    bucket = _bucket_name()

    try:
        res: Any = client.storage.from_(bucket).remove([path])
        if isinstance(res, dict) and res.get("error"):
            raise KycStorageError(str(res["error"]))
    except Exception as exc:  # noqa: BLE001
        raise KycStorageError("Failed to delete file") from exc
