from __future__ import annotations

from rest_framework import serializers

from .models import Rider


class RiderProfileSerializer(serializers.ModelSerializer):
    user_id = serializers.UUIDField(source="user.id", read_only=True)
    name = serializers.CharField(source="user.name", read_only=True)
    phone = serializers.CharField(source="user.phone", read_only=True)

    class Meta:
        model = Rider
        fields = ("user_id", "name", "phone", "is_online", "kyc_status", "current_lat", "current_lng")
        read_only_fields = ("user_id", "name", "phone", "kyc_status")


class RiderOnlineToggleSerializer(serializers.Serializer):
    is_online = serializers.BooleanField()


class RiderLocationUpdateSerializer(serializers.Serializer):
    current_lat = serializers.DecimalField(max_digits=9, decimal_places=6)
    current_lng = serializers.DecimalField(max_digits=9, decimal_places=6)
