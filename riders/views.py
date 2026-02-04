from __future__ import annotations

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from users.permissions import IsRider

from .serializers import (
    RiderLocationUpdateSerializer,
    RiderOnlineToggleSerializer,
    RiderProfileSerializer,
)
from .services.rider_service import get_or_create_rider_for_user, toggle_online, update_location


class RiderViewSet(viewsets.ViewSet):
    permission_classes = [IsRider]

    def _get_rider(self, request):
        return get_or_create_rider_for_user(request.user)

    @action(detail=False, methods=["get"], url_path="me")
    def me(self, request):
        rider = self._get_rider(request)
        return Response(RiderProfileSerializer(rider).data)

    @action(detail=False, methods=["post"], url_path="toggle-online")
    def toggle_online(self, request):
        rider = self._get_rider(request)
        serializer = RiderOnlineToggleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        rider = toggle_online(rider, serializer.validated_data["is_online"])
        return Response(RiderProfileSerializer(rider).data, status=status.HTTP_200_OK)

    @action(detail=False, methods=["post"], url_path="update-location")
    def update_location(self, request):
        rider = self._get_rider(request)
        serializer = RiderLocationUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        rider = update_location(
            rider,
            serializer.validated_data["current_lat"],
            serializer.validated_data["current_lng"],
        )
        return Response(RiderProfileSerializer(rider).data, status=status.HTTP_200_OK)
