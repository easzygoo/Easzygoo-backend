from __future__ import annotations

from django.shortcuts import get_object_or_404
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from riders.services.rider_service import get_or_create_rider_for_user
from users.permissions import IsCustomer, IsRider
from vendors.models import Vendor

from .models import Order
from .serializers import EarningsSummarySerializer, OrderCreateSerializer, OrderSerializer
from .services.order_creation_service import OrderItemInput, place_order_for_customer
from .services.order_service import accept_order, earnings_summary, get_assigned_active_order, mark_delivered, mark_picked


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

    def create(self, request):
        serializer = OrderCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        vendor = get_object_or_404(Vendor, pk=serializer.validated_data["vendor_id"])
        items = [
            OrderItemInput(product_id=str(i["product_id"]), quantity=i["quantity"])
            for i in serializer.validated_data["items"]
        ]

        try:
            order = place_order_for_customer(customer=request.user, vendor=vendor, items=items)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
