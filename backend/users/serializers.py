from __future__ import annotations

from rest_framework import serializers

from .models import Address, User


class UserMeSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "name", "phone", "role", "created_at")
        read_only_fields = fields


class PhoneLoginSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)
    otp = serializers.CharField(max_length=10)
    role = serializers.ChoiceField(choices=User.Role.choices, required=False)

    def validate_phone(self, value: str) -> str:
        v = value.strip()
        if len(v) < 8:
            raise serializers.ValidationError("Enter a valid phone number")
        return v


class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Address
        fields = (
            "id",
            "label",
            "receiver_name",
            "receiver_phone",
            "line1",
            "line2",
            "landmark",
            "city",
            "state",
            "pincode",
            "is_default",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")
