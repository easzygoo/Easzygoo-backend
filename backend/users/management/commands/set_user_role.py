from __future__ import annotations

from django.core.management.base import BaseCommand, CommandError

from users.models import User


class Command(BaseCommand):
    help = "Set (or create) a user's role by phone number."

    def add_arguments(self, parser):
        parser.add_argument(
            "--phone",
            required=True,
            help="Phone number (unique identifier).",
        )
        parser.add_argument(
            "--role",
            required=True,
            choices=[choice for choice, _label in User.Role.choices],
            help="New role.",
        )
        parser.add_argument(
            "--name",
            required=False,
            default=None,
            help="Optional name to set (or use if creating).",
        )
        parser.add_argument(
            "--create",
            action="store_true",
            help="Create the user if it doesn't exist.",
        )

    def handle(self, *args, **options):
        phone: str = (options["phone"] or "").strip()
        role: str = options["role"]
        name: str | None = options.get("name")
        create: bool = bool(options.get("create"))

        if not phone:
            raise CommandError("--phone cannot be blank")

        try:
            user = User.objects.get(phone=phone)
            user.role = role
            if name is not None:
                user.name = name

            update_fields = ["role"]
            if name is not None:
                update_fields.append("name")

            user.save(update_fields=update_fields)
            self.stdout.write(
                self.style.SUCCESS(f"Updated {user.phone}: role={user.role}, name={user.name}")
            )
        except User.DoesNotExist:
            if not create:
                raise CommandError(
                    f"User with phone {phone!r} does not exist. Re-run with --create to create it."
                )

            created_user = User.objects.create(
                phone=phone,
                role=role,
                name=(name or role.title()),
                is_active=True,
            )
            self.stdout.write(
                self.style.SUCCESS(
                    f"Created {created_user.phone}: role={created_user.role}, name={created_user.name}"
                )
            )
