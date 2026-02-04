from rest_framework.permissions import BasePermission


class IsRole(BasePermission):
    required_role: str | None = None

    def has_permission(self, request, view):
        role = getattr(getattr(request, "user", None), "role", None)
        return bool(role and self.required_role and role == self.required_role)


class IsRider(IsRole):
    required_role = "rider"


class IsVendor(IsRole):
    required_role = "vendor"


class IsCustomer(IsRole):
    required_role = "customer"


class IsAdmin(IsRole):
    required_role = "admin"
