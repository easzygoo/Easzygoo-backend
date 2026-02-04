from __future__ import annotations

from rest_framework import serializers

from .models import RiderKyc


class RiderKycSerializer(serializers.ModelSerializer):
    class Meta:
        model = RiderKyc
        fields = (
            "id",
            "rider",
            "status",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "rider", "status", "created_at", "updated_at")


class RiderKycSubmitSerializer(serializers.Serializer):
    aadhaar_front = serializers.ImageField()
    aadhaar_back = serializers.ImageField()
    pan = serializers.ImageField()
    license = serializers.ImageField()
    rc = serializers.ImageField()
    selfie = serializers.ImageField()

    bank_account = serializers.CharField(max_length=32)
    ifsc = serializers.CharField(max_length=16)

    def validate_ifsc(self, value: str) -> str:
        v = value.strip().upper()
        if len(v) < 8:
            raise serializers.ValidationError("Invalid IFSC")
        return v

    def validate_bank_account(self, value: str) -> str:
        v = value.strip()
        if len(v) < 9:
            raise serializers.ValidationError("Invalid bank account")
        return v
