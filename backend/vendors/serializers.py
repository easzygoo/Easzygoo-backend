from __future__ import annotations

from rest_framework import serializers

from .models import Vendor, VendorKyc


class VendorProfileSerializer(serializers.ModelSerializer):
    """Read serializer for vendor profile (GET /api/vendors/me/)."""

    class Meta:
        model = Vendor
        fields = (
            "id",
            "shop_name",
            "address",
            "latitude",
            "longitude",
            "is_open",
        )
        read_only_fields = ("id",)


class VendorProfileUpdateSerializer(serializers.ModelSerializer):
    """Write serializer for vendor profile (PATCH /api/vendors/me/)."""

    class Meta:
        model = Vendor
        fields = (
            "shop_name",
            "address",
            "latitude",
            "longitude",
            "is_open",
        )

    def validate_shop_name(self, value: str) -> str:
        v = (value or "").strip()
        if not v:
            raise serializers.ValidationError("shop_name cannot be empty")
        if len(v) > 160:
            raise serializers.ValidationError("shop_name too long")
        return v

    def validate_address(self, value: str) -> str:
        v = (value or "").strip()
        if not v:
            raise serializers.ValidationError("address cannot be empty")
        return v

    def validate_latitude(self, value):
        if value is None:
            return value
        if value < -90 or value > 90:
            raise serializers.ValidationError("latitude must be between -90 and 90")
        return value

    def validate_longitude(self, value):
        if value is None:
            return value
        if value < -180 or value > 180:
            raise serializers.ValidationError("longitude must be between -180 and 180")
        return value


class VendorSalesSummarySerializer(serializers.Serializer):
    """Response serializer for GET /api/vendors/sales-summary/."""

    today_total_sales = serializers.DecimalField(max_digits=10, decimal_places=2)
    completed_orders_count = serializers.IntegerField()
    pending_orders_count = serializers.IntegerField()


class VendorKycSerializer(serializers.ModelSerializer):
    class Meta:
        model = VendorKyc
        fields = (
            "id",
            "vendor",
            "status",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "vendor", "status", "created_at", "updated_at")


class VendorKycSubmitSerializer(serializers.Serializer):
    id_front = serializers.ImageField()
    id_back = serializers.ImageField()
    shop_license = serializers.ImageField()
    selfie = serializers.ImageField()
