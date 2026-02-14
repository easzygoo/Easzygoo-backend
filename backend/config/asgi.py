"""ASGI config for EaszyGoo backend.

This keeps HTTP served by Django ASGI app, and adds WebSocket routing via Channels.
"""

import os

from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

django_asgi_app = get_asgi_application()

# IMPORTANT: Import ws_realtime only after Django is initialized.
from ws_realtime.middleware.jwt_auth import JwtAuthMiddlewareStack  # noqa: E402
from ws_realtime.routing import websocket_urlpatterns  # noqa: E402

application = ProtocolTypeRouter(
	{
		"http": django_asgi_app,
		"websocket": JwtAuthMiddlewareStack(URLRouter(websocket_urlpatterns)),
	}
)
