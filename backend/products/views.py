from __future__ import annotations

from django.core.exceptions import ObjectDoesNotExist
from rest_framework import status, viewsets
from rest_framework.response import Response

from vendors.permissions import IsVendor

from .serializers import ProductSerializer, ProductWriteSerializer
from .services.product_service import (
    create_vendor_product,
    delete_vendor_product,
    get_vendor_product,
    list_vendor_products,
    update_vendor_product,
)


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


class VendorProductViewSet(viewsets.ViewSet):
    permission_classes = [IsVendor]

    def list(self, request):
        try:
            qs = list_vendor_products(user=request.user)
        except ObjectDoesNotExist:
            return _error("Vendor profile not found", http_status=status.HTTP_404_NOT_FOUND)
        return _success(ProductSerializer(qs, many=True).data)

    def retrieve(self, request, pk=None):
        try:
            product = get_vendor_product(user=request.user, product_id=pk)
        except ObjectDoesNotExist:
            return _error("Product not found", http_status=status.HTTP_404_NOT_FOUND)
        return _success(ProductSerializer(product).data)

    def create(self, request):
        serializer = ProductWriteSerializer(data=request.data)
        if not serializer.is_valid():
            return _error(
                _first_error_message(serializer.errors),
                http_status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            product = create_vendor_product(user=request.user, **serializer.validated_data)
        except ObjectDoesNotExist:
            return _error("Vendor profile not found", http_status=status.HTTP_404_NOT_FOUND)
        return _success(ProductSerializer(product).data, http_status=status.HTTP_201_CREATED)

    def update(self, request, pk=None):
        serializer = ProductWriteSerializer(data=request.data)
        if not serializer.is_valid():
            return _error(
                _first_error_message(serializer.errors),
                http_status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            product = update_vendor_product(user=request.user, product_id=pk, **serializer.validated_data)
        except ObjectDoesNotExist:
            return _error("Product not found", http_status=status.HTTP_404_NOT_FOUND)
        return _success(ProductSerializer(product).data)

    def partial_update(self, request, pk=None):
        serializer = ProductWriteSerializer(data=request.data, partial=True)
        if not serializer.is_valid():
            return _error(
                _first_error_message(serializer.errors),
                http_status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            product = update_vendor_product(user=request.user, product_id=pk, **serializer.validated_data)
        except ObjectDoesNotExist:
            return _error("Product not found", http_status=status.HTTP_404_NOT_FOUND)
        return _success(ProductSerializer(product).data)

    def destroy(self, request, pk=None):
        try:
            delete_vendor_product(user=request.user, product_id=pk)
        except ObjectDoesNotExist:
            return _error("Product not found", http_status=status.HTTP_404_NOT_FOUND)
        return _success({"deleted": True})
