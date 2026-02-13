"""ASGI config for EaszyGoo backend.

This keeps HTTP served by Django ASGI app, and adds WebSocket routing via Channels.
"""

import os

from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application

from ws_realtime.middleware.jwt_auth import JwtAuthMiddlewareStack
from ws_realtime.routing import websocket_urlpatterns

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

django_asgi_app = get_asgi_application()

application = ProtocolTypeRouter(
	{
		"http": django_asgi_app,
		"websocket": JwtAuthMiddlewareStack(URLRouter(websocket_urlpatterns)),
	}
)
