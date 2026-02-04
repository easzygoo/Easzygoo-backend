from rest_framework.routers import DefaultRouter

from .views import CustomerOrderViewSet, OrderViewSet

router = DefaultRouter()
router.register(r"orders", OrderViewSet, basename="orders")
router.register(r"customer/orders", CustomerOrderViewSet, basename="customer-orders")

urlpatterns = router.urls
