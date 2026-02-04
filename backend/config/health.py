from __future__ import annotations

from django.http import JsonResponse


def healthcheck(_request):
    return JsonResponse({"ok": True})
