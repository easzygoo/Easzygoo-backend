from rest_framework.routers import DefaultRouter

from .views import CatalogProductViewSet, VendorProductViewSet

router = DefaultRouter()
router.register(r"products", VendorProductViewSet, basename="products")
router.register(r"vendor/products", VendorProductViewSet, basename="vendor-products")
router.register(r"catalog/products", CatalogProductViewSet, basename="catalog-products")

urlpatterns = router.urls
