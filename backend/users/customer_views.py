from __future__ import annotations

from django.core.exceptions import ObjectDoesNotExist
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from users.permissions import IsCustomer
from users.serializers import AddressSerializer
from users.services.address_service import (
    create_address,
    delete_address,
    get_address,
    list_addresses,
    set_default_address,
    update_address,
)


class CustomerAddressViewSet(viewsets.ViewSet):
    permission_classes = [IsCustomer]

    def list(self, request):
        qs = list_addresses(user=request.user)
        return Response(AddressSerializer(qs, many=True).data)

    def retrieve(self, request, pk=None):
        try:
            address = get_address(user=request.user, address_id=int(pk))
        except (ObjectDoesNotExist, ValueError):
            return Response({"detail": "Address not found"}, status=status.HTTP_404_NOT_FOUND)
        return Response(AddressSerializer(address).data)

    def create(self, request):
        serializer = AddressSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        address = create_address(user=request.user, **serializer.validated_data)
        return Response(AddressSerializer(address).data, status=status.HTTP_201_CREATED)

    def partial_update(self, request, pk=None):
        serializer = AddressSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        try:
            address = update_address(user=request.user, address_id=int(pk), **serializer.validated_data)
        except (ObjectDoesNotExist, ValueError):
            return Response({"detail": "Address not found"}, status=status.HTTP_404_NOT_FOUND)

        return Response(AddressSerializer(address).data)

    def destroy(self, request, pk=None):
        try:
            delete_address(user=request.user, address_id=int(pk))
        except (ObjectDoesNotExist, ValueError):
            return Response({"detail": "Address not found"}, status=status.HTTP_404_NOT_FOUND)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=["post"], url_path="set-default")
    def set_default(self, request, pk=None):
        try:
            address = set_default_address(user=request.user, address_id=int(pk))
        except (ObjectDoesNotExist, ValueError):
            return Response({"detail": "Address not found"}, status=status.HTTP_404_NOT_FOUND)
        return Response(AddressSerializer(address).data)
