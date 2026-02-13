from rest_framework.routers import DefaultRouter

from .customer_views import CustomerAddressViewSet

router = DefaultRouter()
router.register(r"customer/addresses", CustomerAddressViewSet, basename="customer-addresses")

urlpatterns = router.urls
