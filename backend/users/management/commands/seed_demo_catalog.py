from __future__ import annotations

import random
import string
from dataclasses import dataclass

from django.core.management.base import BaseCommand
from django.db import IntegrityError, transaction

from products.models import Product
from users.models import User
from vendors.models import Vendor, VendorKyc


DEFAULT_PHONE_PREFIX = "98"  # 10 digits total
DEFAULT_VENDORS = 3
DEFAULT_PRODUCTS_PER_VENDOR = 6


@dataclass(frozen=True)
class SeededVendor:
    phone: str
    shop_name: str
    products_created: int


def _rand_digits(rng: random.Random, n: int) -> str:
    return "".join(rng.choice(string.digits) for _ in range(n))


def _unique_phone(rng: random.Random, *, prefix: str) -> str:
    # India-style 10-digit numbers; keep it simple.
    # If prefix is 2 digits, generate remaining 8.
    prefix = prefix.strip()
    if not prefix.isdigit():
        raise ValueError("prefix must be numeric")
    if len(prefix) >= 10:
        raise ValueError("prefix must be shorter than 10 digits")

    remaining = 10 - len(prefix)
    return f"{prefix}{_rand_digits(rng, remaining)}"


def _money(rng: random.Random, *, min_value: int = 10, max_value: int = 350) -> str:
    # Return string so DecimalField can parse; keep .00.
    value = rng.randint(min_value, max_value)
    return f"{value}.00"


class Command(BaseCommand):
    help = "Seed demo vendors + approved KYC + products for local testing (OTP is always 0000)."

    def add_arguments(self, parser):
        parser.add_argument("--vendors", type=int, default=DEFAULT_VENDORS)
        parser.add_argument("--products-per-vendor", type=int, default=DEFAULT_PRODUCTS_PER_VENDOR)
        parser.add_argument("--phone-prefix", type=str, default=DEFAULT_PHONE_PREFIX)
        parser.add_argument(
            "--seed",
            type=int,
            default=None,
            help="Optional RNG seed for reproducible output.",
        )
        parser.add_argument(
            "--force-role",
            action="store_true",
            help="If a generated phone already exists, force-update user.role to vendor.",
        )

    def handle(self, *args, **options):
        vendors_count: int = options["vendors"]
        products_per_vendor: int = options["products_per_vendor"]
        phone_prefix: str = options["phone_prefix"]
        seed: int | None = options["seed"]
        force_role: bool = bool(options["force_role"])

        if vendors_count <= 0:
            raise SystemExit("--vendors must be > 0")
        if products_per_vendor < 0:
            raise SystemExit("--products-per-vendor must be >= 0")

        rng = random.Random(seed)

        created: list[SeededVendor] = []

        # Keep locations near one another (Bengaluru-ish) but unique.
        base_lat = 12.9716
        base_lng = 77.5946

        product_names = [
            "Milk",
            "Bread",
            "Eggs",
            "Rice",
            "Sugar",
            "Tea",
            "Coffee",
            "Biscuits",
            "Chips",
            "Soap",
            "Shampoo",
            "Toothpaste",
        ]

        for vendor_index in range(vendors_count):
            # Retry a few times in case of phone collisions.
            user: User | None = None
            phone: str | None = None

            for _ in range(20):
                try_phone = _unique_phone(rng, prefix=phone_prefix)
                try:
                    with transaction.atomic():
                        user, user_created = User.objects.get_or_create(
                            phone=try_phone,
                            defaults={
                                "name": f"Vendor {vendor_index + 1}",
                                "role": User.Role.VENDOR,
                                "is_active": True,
                            },
                        )
                        if not user_created and force_role and user.role != User.Role.VENDOR:
                            user.role = User.Role.VENDOR
                            user.save(update_fields=["role"])

                    phone = try_phone
                    break
                except IntegrityError:
                    user = None
                    phone = None
                    continue

            if not user or not phone:
                raise SystemExit("Failed to generate a unique phone number; try a different --phone-prefix")

            shop_name = f"Demo Shop {vendor_index + 1}"

            lat = base_lat + (vendor_index * 0.001) + rng.uniform(-0.0003, 0.0003)
            lng = base_lng + (vendor_index * 0.001) + rng.uniform(-0.0003, 0.0003)

            vendor, _ = Vendor.objects.update_or_create(
                user=user,
                defaults={
                    "shop_name": shop_name,
                    "address": f"{shop_name}, Demo Address, Bengaluru",
                    "latitude": round(lat, 6),
                    "longitude": round(lng, 6),
                    "is_open": True,
                },
            )

            VendorKyc.objects.update_or_create(
                vendor=vendor,
                defaults={
                    "status": VendorKyc.Status.APPROVED,
                    "id_front_path": "",
                    "id_back_path": "",
                    "shop_license_path": "",
                    "selfie_path": "",
                },
            )

            # Create products (always active, in stock)
            products_created = 0
            for product_index in range(products_per_vendor):
                base_name = rng.choice(product_names)
                name = f"{base_name} ({vendor_index + 1}-{product_index + 1})"
                Product.objects.create(
                    vendor=vendor,
                    name=name,
                    description=f"Demo product: {base_name}",
                    price=_money(rng),
                    stock=rng.randint(5, 80),
                    is_active=True,
                )
                products_created += 1

            created.append(
                SeededVendor(
                    phone=phone,
                    shop_name=shop_name,
                    products_created=products_created,
                )
            )

        self.stdout.write(self.style.SUCCESS("Seed complete."))
        self.stdout.write("\nVendor logins (OTP is always 0000):")
        for v in created:
            self.stdout.write(f"- phone: {v.phone} | shop: {v.shop_name} | products: {v.products_created}")
