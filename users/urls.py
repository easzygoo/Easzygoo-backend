from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import MeView, PhoneLoginView

urlpatterns = [
    path("login/", PhoneLoginView.as_view(), name="phone-login"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("me/", MeView.as_view(), name="me"),
]
