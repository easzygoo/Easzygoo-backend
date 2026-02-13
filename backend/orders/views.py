from __future__ import annotations

from django.shortcuts import get_object_or_404
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from riders.services.rider_service import get_or_create_rider_for_user
from users.permissions import IsCustomer, IsRider
from vendors.permissions import IsVendor
from vendors.models import Vendor
from users.models import Address

from .models import Order
from .serializers import EarningsSummarySerializer, OrderCreateSerializer, OrderSerializer
from .services.customer_order_service import get_customer_order, list_customer_orders
from .services.order_creation_service import OrderItemInput, place_order_for_customer
from .services.order_service import accept_order, earnings_summary, get_assigned_active_order, mark_delivered, mark_picked
from .services.vendor_order_service import (
    accept_vendor_order,
    cancel_vendor_order,
    get_vendor_order,
    list_vendor_orders,
    mark_vendor_order_ready,
    reject_vendor_order,
)


def _vendor_success(data, *, http_status: int = status.HTTP_200_OK) -> Response:
    return Response({"success": True, "data": data}, status=http_status)


def _vendor_error(message: str, *, http_status: int) -> Response:
    return Response({"success": False, "error": message}, status=http_status)


class VendorOrderViewSet(viewsets.ViewSet):
    permission_classes = [IsVendor]

    def list(self, request):
        status_param = request.query_params.get("status")
        try:
            qs = list_vendor_orders(user=request.user, status=status_param)
        except Exception:
            return _vendor_error("Vendor profile not found", http_status=status.HTTP_404_NOT_FOUND)

        return _vendor_success(OrderSerializer(qs, many=True).data)

    def retrieve(self, request, pk=None):
        try:
            order = get_vendor_order(user=request.user, order_id=pk)
        except Exception:
            return _vendor_error("Order not found", http_status=status.HTTP_404_NOT_FOUND)

        return _vendor_success(OrderSerializer(order).data)

    @action(detail=True, methods=["post"], url_path="ready")
    def mark_ready(self, request, pk=None):
        try:
            order = mark_vendor_order_ready(user=request.user, order_id=pk)
        except ValueError as e:
            return _vendor_error(str(e), http_status=status.HTTP_400_BAD_REQUEST)
        except Exception:
            return _vendor_error("Order not found", http_status=status.HTTP_404_NOT_FOUND)

        return _vendor_success(OrderSerializer(order).data)

    @action(detail=True, methods=["post"], url_path="accept")
    def accept(self, request, pk=None):
        try:
            order = accept_vendor_order(user=request.user, order_id=pk)
        except ValueError as e:
            return _vendor_error(str(e), http_status=status.HTTP_400_BAD_REQUEST)
        except Exception:
            return _vendor_error("Order not found", http_status=status.HTTP_404_NOT_FOUND)

        return _vendor_success(OrderSerializer(order).data)

    @action(detail=True, methods=["post"], url_path="reject")
    def reject(self, request, pk=None):
        try:
            order = reject_vendor_order(user=request.user, order_id=pk)
        except ValueError as e:
            return _vendor_error(str(e), http_status=status.HTTP_400_BAD_REQUEST)
        except Exception:
            return _vendor_error("Order not found", http_status=status.HTTP_404_NOT_FOUND)

        return _vendor_success(OrderSerializer(order).data)

    @action(detail=True, methods=["post"], url_path="cancel")
    def cancel(self, request, pk=None):
        try:
            order = cancel_vendor_order(user=request.user, order_id=pk)
        except ValueError as e:
            return _vendor_error(str(e), http_status=status.HTTP_400_BAD_REQUEST)
        except Exception:
            return _vendor_error("Order not found", http_status=status.HTTP_404_NOT_FOUND)

        return _vendor_success(OrderSerializer(order).data)


class OrderViewSet(viewsets.ViewSet):
    permission_classes = [IsRider]

    def _get_rider(self, request):
        return get_or_create_rider_for_user(request.user)

    @action(detail=False, methods=["get"], url_path="assigned-active")
    def assigned_active(self, request):
        rider = self._get_rider(request)
        order = get_assigned_active_order(rider)
        if not order:
            return Response({"detail": "No active order"}, status=status.HTTP_404_NOT_FOUND)
        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=["post"], url_path="accept")
    def accept(self, request, pk=None):
        rider = self._get_rider(request)
        order = get_object_or_404(Order, pk=pk)
        try:
            order = accept_order(rider=rider, order=order)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=["post"], url_path="picked")
    def picked(self, request, pk=None):
        rider = self._get_rider(request)
        order = get_object_or_404(Order, pk=pk)
        try:
            order = mark_picked(rider=rider, order=order)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=["post"], url_path="delivered")
    def delivered(self, request, pk=None):
        rider = self._get_rider(request)
        order = get_object_or_404(Order, pk=pk)
        try:
            order = mark_delivered(rider=rider, order=order)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(OrderSerializer(order).data)

    @action(detail=False, methods=["get"], url_path="earnings-summary")
    def earnings(self, request):
        rider = self._get_rider(request)
        data = earnings_summary(rider)
        return Response(EarningsSummarySerializer(data).data)


class CustomerOrderViewSet(viewsets.ViewSet):
    permission_classes = [IsCustomer]

    def list(self, request):
        qs = list_customer_orders(customer=request.user)
        return Response(OrderSerializer(qs, many=True).data)

    def retrieve(self, request, pk=None):
        try:
            order = get_customer_order(customer=request.user, order_id=pk)
        except Order.DoesNotExist:
            return Response({"detail": "Order not found"}, status=status.HTTP_404_NOT_FOUND)
        return Response(OrderSerializer(order).data)

    def create(self, request):
        serializer = OrderCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        vendor = get_object_or_404(Vendor, pk=serializer.validated_data["vendor_id"])
        address = None
        address_id = serializer.validated_data.get("address_id")
        if address_id is not None:
            address = get_object_or_404(Address, pk=address_id, user=request.user)

        payment_method = serializer.validated_data.get("payment_method") or Order.PaymentMethod.COD
        items = [
            OrderItemInput(product_id=str(i["product_id"]), quantity=i["quantity"])
            for i in serializer.validated_data["items"]
        ]

        try:
            order = place_order_for_customer(
                customer=request.user,
                vendor=vendor,
                items=items,
                delivery_address=address,
                payment_method=payment_method,
            )
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
