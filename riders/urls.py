from rest_framework.routers import DefaultRouter

from .views import RiderViewSet

router = DefaultRouter()
router.register(r"riders", RiderViewSet, basename="riders")

urlpatterns = router.urls
