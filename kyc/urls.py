from rest_framework.routers import DefaultRouter

from .views import RiderKycViewSet

router = DefaultRouter()
router.register(r"kyc", RiderKycViewSet, basename="kyc")

urlpatterns = router.urls
