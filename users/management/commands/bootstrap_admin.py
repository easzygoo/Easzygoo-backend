from __future__ import annotations

import os

from django.core.management.base import BaseCommand, CommandError

from users.models import User


class Command(BaseCommand):
    help = "Create/update an admin user from environment variables (non-interactive)."

    def handle(self, *args, **options):
        phone = (os.getenv("DJANGO_ADMIN_PHONE") or "").strip()
        name = (os.getenv("DJANGO_ADMIN_NAME") or "").strip()
        password = os.getenv("DJANGO_ADMIN_PASSWORD")

        if not phone:
            raise CommandError("DJANGO_ADMIN_PHONE is required")
        if not name:
            raise CommandError("DJANGO_ADMIN_NAME is required")
        if not password:
            raise CommandError("DJANGO_ADMIN_PASSWORD is required")

        user, created = User.objects.get_or_create(
            phone=phone,
            defaults={
                "name": name,
                "role": User.Role.ADMIN,
                "is_active": True,
                "is_staff": True,
                "is_superuser": True,
            },
        )

        changed_fields: list[str] = []

        if user.name != name:
            user.name = name
            changed_fields.append("name")

        if user.role != User.Role.ADMIN:
            user.role = User.Role.ADMIN
            changed_fields.append("role")

        if not user.is_active:
            user.is_active = True
            changed_fields.append("is_active")

        if not user.is_staff:
            user.is_staff = True
            changed_fields.append("is_staff")

        if not user.is_superuser:
            user.is_superuser = True
            changed_fields.append("is_superuser")

        user.set_password(password)
        # Password always set; include for save.
        changed_fields.append("password")

        user.save()

        if created:
            self.stdout.write(self.style.SUCCESS(f"Admin created: {user.phone}"))
        else:
            self.stdout.write(self.style.SUCCESS(f"Admin updated: {user.phone}"))
