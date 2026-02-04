from __future__ import annotations

from django.core.exceptions import ObjectDoesNotExist
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import APIException, PermissionDenied, ValidationError
from rest_framework.response import Response

from vendors.permissions import IsVendor
from vendors.serializers import (
    VendorKycSerializer,
    VendorKycSubmitSerializer,
    VendorProfileSerializer,
    VendorProfileUpdateSerializer,
    VendorSalesSummarySerializer,
)
from vendors.services.vendor_service import (
    get_vendor_dashboard,
    get_vendor_for_user,
    get_vendor_sales_summary,
    toggle_vendor_open,
    update_vendor_profile,
)
from vendors.services.vendor_kyc_service import get_vendor_kyc_status_for_user, submit_vendor_kyc_for_user


def _success(data, *, http_status: int = status.HTTP_200_OK) -> Response:
    return Response({"success": True, "data": data}, status=http_status)


def _first_error_message(errors) -> str:
    if isinstance(errors, (list, tuple)):
        return _first_error_message(errors[0]) if errors else "Invalid request"
    if isinstance(errors, dict):
        for v in errors.values():
            return _first_error_message(v)
        return "Invalid request"
    return str(errors)


def _error(message: str, *, http_status: int) -> Response:
    return Response({"success": False, "error": message}, status=http_status)


class VendorViewSet(viewsets.ViewSet):
    permission_classes = [IsVendor]

    @action(detail=False, methods=["get", "patch"], url_path="me")
    def me(self, request):
        try:
            vendor = get_vendor_for_user(user=request.user)
        except ObjectDoesNotExist:
            return _error("Vendor profile not found", http_status=status.HTTP_404_NOT_FOUND)

        if request.method.lower() == "get":
            return _success(VendorProfileSerializer(vendor).data)

        serializer = VendorProfileUpdateSerializer(vendor, data=request.data, partial=True)
        if not serializer.is_valid():
            return _error(
                _first_error_message(serializer.errors),
                http_status=status.HTTP_400_BAD_REQUEST,
            )

        updated = update_vendor_profile(user=request.user, **serializer.validated_data)
        return _success(VendorProfileSerializer(updated).data)

    @action(detail=False, methods=["post"], url_path="toggle-open")
    def toggle_open(self, request):
        try:
            is_open = toggle_vendor_open(user=request.user)
        except ObjectDoesNotExist:
            return _error("Vendor profile not found", http_status=status.HTTP_404_NOT_FOUND)
        return _success({"is_open": is_open})

    @action(detail=False, methods=["get"], url_path="dashboard")
    def dashboard(self, request):
        try:
            payload = get_vendor_dashboard(user=request.user)
        except ObjectDoesNotExist:
            return _error("Vendor profile not found", http_status=status.HTTP_404_NOT_FOUND)
        return _success(payload)

    @action(detail=False, methods=["get"], url_path="sales-summary")
    def sales_summary(self, request):
        try:
            summary = get_vendor_sales_summary(user=request.user)
        except ObjectDoesNotExist:
            return _error("Vendor profile not found", http_status=status.HTTP_404_NOT_FOUND)

        data = VendorSalesSummarySerializer(
            {
                "today_total_sales": summary.today_total_sales,
                "completed_orders_count": summary.completed_orders_count,
                "pending_orders_count": summary.pending_orders_count,
            }
        ).data
        return _success(data)

    @action(detail=False, methods=["get"], url_path="verification/status")
    def verification_status(self, request):
        try:
            status_payload = get_vendor_kyc_status_for_user(request.user)
        except PermissionDenied as e:
            return _error(str(e.detail), http_status=status.HTTP_403_FORBIDDEN)
        except ValidationError as e:
            return _error(_first_error_message(e.detail), http_status=status.HTTP_400_BAD_REQUEST)
        except APIException as e:
            return _error(str(e.detail), http_status=getattr(e, "status_code", status.HTTP_400_BAD_REQUEST))

        return _success(status_payload)

    @action(detail=False, methods=["post"], url_path="verification/submit")
    def verification_submit(self, request):
        serializer = VendorKycSubmitSerializer(data=request.data)
        if not serializer.is_valid():
            return _error(_first_error_message(serializer.errors), http_status=status.HTTP_400_BAD_REQUEST)

        try:
            kyc = submit_vendor_kyc_for_user(user=request.user, payload=serializer.validated_data)
        except PermissionDenied as e:
            return _error(str(e.detail), http_status=status.HTTP_403_FORBIDDEN)
        except ValidationError as e:
            return _error(_first_error_message(e.detail), http_status=status.HTTP_400_BAD_REQUEST)
        except APIException as e:
            return _error(str(e.detail), http_status=getattr(e, "status_code", status.HTTP_400_BAD_REQUEST))

        return _success(VendorKycSerializer(kyc).data, http_status=status.HTTP_201_CREATED)
