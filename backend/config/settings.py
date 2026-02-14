from __future__ import annotations

import logging
import os
from pathlib import Path

import dj_database_url
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

# Load env from backend/.env for local development.
# In production (Railway/AWS), env vars should be injected by the platform.
load_dotenv(BASE_DIR / ".env")


def _env_bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "t", "yes", "y", "on"}


SECRET_KEY = os.getenv("DJANGO_SECRET_KEY") or os.getenv("SECRET_KEY") or "dev-insecure-change-me"
DEBUG = _env_bool("DJANGO_DEBUG", default=_env_bool("DEBUG", default=False))

_allowed_hosts_raw = os.getenv("DJANGO_ALLOWED_HOSTS") or os.getenv("ALLOWED_HOSTS") or "localhost,127.0.0.1"

# Local dev convenience: when DEBUG is enabled and no explicit hosts are set,
# allow all hosts so Android devices on LAN can reach the server.
_using_default_allowed_hosts = _allowed_hosts_raw.strip() == "localhost,127.0.0.1"
if DEBUG and _using_default_allowed_hosts:
    ALLOWED_HOSTS = ["*"]
else:
    ALLOWED_HOSTS = [h.strip() for h in _allowed_hosts_raw.split(",") if h.strip()]

INSTALLED_APPS = [
    # Django
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",

    # Realtime
    "channels",

    # Third-party
    "rest_framework",
    "corsheaders",

    # Local apps (modular monolith)
    "users",
    "riders",
    "vendors",
    "products",
    "orders",
    "kyc",
    "payments",
]

AUTHENTICATION_BACKENDS = [
    "django.contrib.auth.backends.ModelBackend",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "config.middleware.request_logging.RequestLoggingMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    }
]

WSGI_APPLICATION = "config.wsgi.application"

# Channels / ASGI
ASGI_APPLICATION = "config.asgi.application"


# Database (Supabase PostgreSQL)
# Provide DATABASE_URL in .env / platform env vars.
DATABASE_URL = os.getenv("DATABASE_URL", "")
DATABASE_SSL_REQUIRE = _env_bool("DATABASE_SSL_REQUIRE", default=bool(DATABASE_URL))

if DATABASE_URL:
    DATABASES = {
        "default": dj_database_url.config(
            default=DATABASE_URL,
            conn_max_age=int(os.getenv("DATABASE_CONN_MAX_AGE", "600")),
            ssl_require=DATABASE_SSL_REQUIRE,
        )
    }
else:
    # Local fallback so the project boots without Postgres.
    # Set DATABASE_URL to your Supabase connection string for real environments.
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }


AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]


LANGUAGE_CODE = "en-us"
TIME_ZONE = os.getenv("DJANGO_TIME_ZONE", "UTC")
USE_I18N = True
USE_TZ = True


# Static / media
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"


DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# Custom user model
AUTH_USER_MODEL = "users.User"


# DRF + JWT
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": int(os.getenv("DRF_PAGE_SIZE", "20")),
    # Throttle rates are only applied to views that explicitly enable throttling.
    "DEFAULT_THROTTLE_RATES": {
        "anon": os.getenv("DRF_THROTTLE_ANON", "10/min"),
        "user": os.getenv("DRF_THROTTLE_USER", "60/min"),
    },
}


# Realtime (Redis channel layer)
REDIS_URL = os.getenv("REDIS_URL", "").strip()

if REDIS_URL:
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels_redis.core.RedisChannelLayer",
            "CONFIG": {
                "hosts": [REDIS_URL],
            },
        }
    }
else:
    # Local fallback so the project can boot without Redis.
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels.layers.InMemoryChannelLayer",
        }
    }

_settings_logger = logging.getLogger(__name__)
if CHANNEL_LAYERS.get("default", {}).get("BACKEND") == "channels.layers.InMemoryChannelLayer":
    # InMemoryChannelLayer is fine for local dev and single-worker demos, but unsafe
    # for multi-worker deployments. Require an explicit opt-in if DEBUG is False.
    ALLOW_INMEMORY_CHANNEL_LAYER = _env_bool("ALLOW_INMEMORY_CHANNEL_LAYER", default=False)

    if not DEBUG and not REDIS_URL and not ALLOW_INMEMORY_CHANNEL_LAYER:
        raise RuntimeError(
            "CHANNEL_LAYERS is configured with InMemoryChannelLayer, which is unsafe for multi-process "
            "deployments. Set REDIS_URL (channels_redis) when DEBUG is False, or set "
            "ALLOW_INMEMORY_CHANNEL_LAYER=1 for single-worker demo environments."
        )
    _settings_logger.warning(
        "CHANNEL_LAYERS is using InMemoryChannelLayer; realtime features won't work across multiple workers.",
        extra={"event": "channels_inmemory_warning"},
    )


# Cache (used to avoid DB hits in WebSocket consumers)
if REDIS_URL:
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.redis.RedisCache",
            "LOCATION": REDIS_URL,
        }
    }
else:
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        }
    }


LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "json": {
            "()": "config.logging.JsonFormatter",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "json",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": os.getenv("DJANGO_LOG_LEVEL", "INFO"),
    },
}


# CORS (configure for your mobile/web clients)
CORS_ALLOWED_ORIGINS = [
    o.strip() for o in os.getenv("CORS_ALLOWED_ORIGINS", "").split(",") if o.strip()
]
CORS_ALLOW_ALL_ORIGINS = _env_bool("CORS_ALLOW_ALL_ORIGINS", default=DEBUG and not bool(CORS_ALLOWED_ORIGINS))
CORS_ALLOW_CREDENTIALS = _env_bool("CORS_ALLOW_CREDENTIALS", default=False)

# CSRF trusted origins (if you ever use cookie auth / admin behind proxy)
CSRF_TRUSTED_ORIGINS = [
    o.strip() for o in os.getenv("CSRF_TRUSTED_ORIGINS", "").split(",") if o.strip()
]


# Security (baseline; tune later for Railway/AWS)
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
USE_X_FORWARDED_HOST = True
SECURE_SSL_REDIRECT = _env_bool("SECURE_SSL_REDIRECT", default=not DEBUG)
SESSION_COOKIE_SECURE = _env_bool("SESSION_COOKIE_SECURE", default=False)
CSRF_COOKIE_SECURE = _env_bool("CSRF_COOKIE_SECURE", default=False)

