from __future__ import annotations

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .serializers import RiderKycSerializer, RiderKycSubmitSerializer
from .services.kyc_service import generate_signed_document_url, get_kyc_status_for_user, submit_kyc_for_user


class RiderKycViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=["get"], url_path="status")
    def status(self, request):
        return Response(get_kyc_status_for_user(request.user))

    @action(detail=False, methods=["post"], url_path="submit")
    def submit(self, request):
        serializer = RiderKycSubmitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        kyc = submit_kyc_for_user(user=request.user, payload=serializer.validated_data)
        return Response(RiderKycSerializer(kyc).data, status=status.HTTP_201_CREATED)

    @action(
        detail=False,
        methods=["get"],
        url_path=r"view/(?P<document_type>[^/]+)",
    )
    def view_document(self, request, document_type: str):
        rider_user_id = request.query_params.get("rider_user_id")
        result = generate_signed_document_url(
            request_user=request.user,
            document_type=document_type,
            rider_user_id=rider_user_id,
        )
        return Response({"url": result.url}, status=status.HTTP_200_OK)
