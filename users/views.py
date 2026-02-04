from __future__ import annotations

from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import PhoneLoginSerializer, UserMeSerializer
from .services.auth_service import login_with_phone


class PhoneLoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PhoneLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        phone = serializer.validated_data["phone"]
        otp = serializer.validated_data["otp"]

        try:
            result = login_with_phone(phone=phone, otp=otp)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        return Response(
            {
                "user": UserMeSerializer(result.user).data,
                "access": result.access,
                "refresh": result.refresh,
                "otp_mode": "mock",
                "mock_otp": "0000",
            },
            status=status.HTTP_200_OK,
        )


class MeView(APIView):
    def get(self, request):
        return Response(UserMeSerializer(request.user).data)
