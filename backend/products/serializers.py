from __future__ import annotations

from rest_framework import serializers

from .models import Product


class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = (
            "id",
            "name",
            "description",
            "price",
            "stock",
            "is_active",
        )


class CatalogProductSerializer(serializers.ModelSerializer):
    vendor_id = serializers.IntegerField(source="vendor.id", read_only=True)
    vendor_name = serializers.CharField(source="vendor.shop_name", read_only=True)

    class Meta:
        model = Product
        fields = (
            "id",
            "vendor_id",
            "vendor_name",
            "name",
            "description",
            "price",
            "stock",
            "is_active",
        )


class ProductWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = (
            "name",
            "description",
            "price",
            "stock",
            "is_active",
        )
