from __future__ import annotations

from rest_framework.permissions import BasePermission


class IsVendor(BasePermission):
    """Allows access only to authenticated users with role == 'vendor'.

    We keep this permission Vendor-domain specific (instead of reusing users.permissions)
    so Vendor APIs can evolve independently without touching Rider/Customer logic.
    """

    message = "Vendor authentication required"

    def has_permission(self, request, view) -> bool:
        user = getattr(request, "user", None)
        if not user or not getattr(user, "is_authenticated", False):
            return False

        return getattr(user, "role", None) == "vendor"
