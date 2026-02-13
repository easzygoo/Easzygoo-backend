from __future__ import annotations

from django.urls import path

from ws_realtime.consumers.location_consumer import LocationConsumer
from ws_realtime.consumers.order_consumer import OrderConsumer

websocket_urlpatterns = [
    path("ws/location/", LocationConsumer.as_asgi()),
    path("ws/order/<str:order_id>/", OrderConsumer.as_asgi()),
]
