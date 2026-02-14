from __future__ import annotations

from rest_framework import serializers

from .models import Order, OrderItem


class OrderDeliveryAddressSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    label = serializers.CharField()
    receiver_name = serializers.CharField()
    receiver_phone = serializers.CharField()
    line1 = serializers.CharField()
    line2 = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    landmark = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    city = serializers.CharField()
    state = serializers.CharField()
    pincode = serializers.CharField()


class OrderItemSerializer(serializers.ModelSerializer):
    product_id = serializers.UUIDField(source="product.id", read_only=True)
    product_name = serializers.CharField(source="product.name", read_only=True)

    class Meta:
        model = OrderItem
        fields = ("product_id", "product_name", "quantity", "price")


class OrderSerializer(serializers.ModelSerializer):
    vendor_id = serializers.IntegerField(source="vendor.id", read_only=True)
    vendor_name = serializers.CharField(source="vendor.shop_name", read_only=True)
    rider_id = serializers.IntegerField(source="rider.id", read_only=True)
    customer_id = serializers.UUIDField(source="customer.id", read_only=True)
    delivery_address_id = serializers.IntegerField(source="delivery_address.id", read_only=True)
    delivery_address = OrderDeliveryAddressSerializer(source="delivery_address", read_only=True)
    items = OrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = (
            "id",
            "customer_id",
            "vendor_id",
            "vendor_name",
            "rider_id",
            "delivery_address_id",
            "delivery_address",
            "status",
            "total_amount",
            "payment_method",
            "payment_status",
            "created_at",
            "updated_at",
            "items",
        )
        read_only_fields = fields


class EarningsSummarySerializer(serializers.Serializer):
    delivered_orders = serializers.IntegerField()
    total_delivered_amount = serializers.DecimalField(max_digits=10, decimal_places=2)


class OrderCreateItemInputSerializer(serializers.Serializer):
    product_id = serializers.UUIDField()
    quantity = serializers.IntegerField(min_value=1)


class OrderCreateSerializer(serializers.Serializer):
    vendor_id = serializers.IntegerField()
    address_id = serializers.IntegerField(required=False)
    payment_method = serializers.ChoiceField(choices=Order.PaymentMethod.choices, required=False)
    items = OrderCreateItemInputSerializer(many=True, allow_empty=False)
