from __future__ import annotations

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

from .health import healthcheck
from .ready import readycheck

urlpatterns = [
    path("", healthcheck),
    path("admin/", admin.site.urls),
    path("api/health/", healthcheck),
    path("api/ready/", readycheck),
    path("api/auth/", include("users.urls")),
    path("api/", include("users.customer_urls")),
    path("api/", include("riders.urls")),
    path("api/", include("orders.urls")),
    path("api/", include("kyc.urls")),
    path("api/", include("vendors.urls")),
    path("api/", include("products.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
