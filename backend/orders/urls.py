from rest_framework.routers import DefaultRouter

from .views import CustomerOrderViewSet, OrderViewSet, VendorOrderViewSet

router = DefaultRouter()
router.register(r"orders", OrderViewSet, basename="orders")
router.register(r"customer/orders", CustomerOrderViewSet, basename="customer-orders")
router.register(r"orders/vendor", VendorOrderViewSet, basename="orders-vendor")
router.register(r"vendor/orders", VendorOrderViewSet, basename="vendor-orders")

urlpatterns = router.urls
