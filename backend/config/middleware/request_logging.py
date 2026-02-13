from __future__ import annotations

import logging
import time
import uuid


logger = logging.getLogger("http")


class RequestLoggingMiddleware:
    """Adds X-Request-ID and logs requests with duration.

    Keeps behavior minimal to avoid breaking existing APIs.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        request.request_id = request_id

        start = time.perf_counter()
        try:
            response = self.get_response(request)
        except Exception:
            duration_ms = int((time.perf_counter() - start) * 1000)
            logger.exception(
                "request_error",
                extra={
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.path,
                    "status_code": 500,
                    "duration_ms": duration_ms,
                },
            )
            raise

        duration_ms = int((time.perf_counter() - start) * 1000)

        try:
            response["X-Request-ID"] = request_id
        except Exception:
            pass

        logger.info(
            "request",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.path,
                "status_code": getattr(response, "status_code", None),
                "duration_ms": duration_ms,
            },
        )
        return response
