from __future__ import annotations

from django.conf import settings
from django.db import connection
from django.http import JsonResponse


def _check_db() -> tuple[bool, str | None]:
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        return True, None
    except Exception as e:
        return False, str(e)


def _check_redis() -> tuple[bool, str | None]:
    redis_url = getattr(settings, "REDIS_URL", "")
    if not redis_url:
        # If Redis isn't configured, readiness only depends on DB.
        return True, None

    client = None
    try:
        import redis  # type: ignore

        client = redis.from_url(redis_url)
        client.ping()
        return True, None
    except Exception as e:
        return False, str(e)
    finally:
        try:
            if client is not None:
                client.close()
        except Exception:
            # Readiness check should never fail due to close issues.
            pass


def readycheck(_request):
    db_ok, db_err = _check_db()
    redis_ok, redis_err = _check_redis()

    ok = bool(db_ok and redis_ok)

    payload = {
        "ok": ok,
        "checks": {
            "db": {"ok": db_ok, "error": db_err},
            "redis": {"ok": redis_ok, "error": redis_err},
        },
    }

    return JsonResponse(payload, status=200 if ok else 503)
