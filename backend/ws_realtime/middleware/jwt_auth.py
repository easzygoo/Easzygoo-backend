from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Iterable
from urllib.parse import parse_qs

import logging
from asgiref.sync import sync_to_async
from channels.exceptions import DenyConnection
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.authentication import JWTAuthentication


logger = logging.getLogger("realtime")


@dataclass(frozen=True)
class JwtScopeAuthResult:
    user: object
    token_provided: bool


def _headers_to_dict(headers: Iterable[tuple[bytes, bytes]]) -> dict[str, str]:
    out: dict[str, str] = {}
    for k, v in headers:
        try:
            out[k.decode("latin1").lower()] = v.decode("latin1")
        except Exception:
            # Skip malformed header values
            continue
    return out


def _get_bearer_token_from_authorization(value: str | None) -> str | None:
    if not value:
        return None
    parts = value.strip().split()
    if len(parts) == 2 and parts[0].lower() == "bearer":
        return parts[1]
    return None


def _get_token_from_query_string(query_string: bytes) -> str | None:
    if not query_string:
        return None

    try:
        qs = parse_qs(query_string.decode("utf-8"), keep_blank_values=False)
    except Exception:
        return None

    # Allow a few common names to make client integration easy.
    for key in ("token", "access", "jwt"):
        values = qs.get(key)
        if values:
            token = (values[0] or "").strip()
            if token:
                return token

    return None


async def _authenticate_scope(scope) -> JwtScopeAuthResult:
    token = _get_token_from_query_string(scope.get("query_string", b""))

    headers = _headers_to_dict(scope.get("headers", []))
    if not token:
        token = _get_bearer_token_from_authorization(headers.get("authorization"))

    if not token:
        logger.info(
            "ws_anonymous",
            extra={
                "event": "ws_anonymous",
                "client": str(scope.get("client")),
            },
        )
        return JwtScopeAuthResult(user=AnonymousUser(), token_provided=False)

    jwt_auth = JWTAuthentication()

    try:
        validated = await sync_to_async(jwt_auth.get_validated_token)(token)
        user = await sync_to_async(jwt_auth.get_user)(validated)
    except Exception as e:
        # Spec: reject invalid tokens (but allow missing token to proceed as anonymous).
        logger.info(
            "ws_invalid_token",
            extra={
                "event": "ws_invalid_token",
                "client": str(scope.get("client")),
            },
        )
        raise DenyConnection("Invalid token") from e

    return JwtScopeAuthResult(user=user, token_provided=True)


class JwtAuthMiddleware:
    """Channels middleware that authenticates WebSocket connections using SimpleJWT.

    Token sources:
    - Query string: `?token=<jwt>` (also supports `access` or `jwt`)
    - Header: `Authorization: Bearer <jwt>`

    Behavior:
    - Missing token: sets `scope['user'] = AnonymousUser()`
    - Invalid token: denies the connection
    """

    def __init__(self, inner: Callable):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        result = await _authenticate_scope(scope)
        scope["user"] = result.user
        scope["jwt_token_provided"] = result.token_provided
        return await self.inner(scope, receive, send)


def JwtAuthMiddlewareStack(inner: Callable) -> JwtAuthMiddleware:
    return JwtAuthMiddleware(inner)
