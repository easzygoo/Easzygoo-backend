from __future__ import annotations

from django.core.exceptions import ObjectDoesNotExist

from products.models import Product
from vendors.models import Vendor
from vendors.services.vendor_service import get_vendor_for_user


def list_vendor_products(*, user):
    vendor = get_vendor_for_user(user=user)
    return Product.objects.filter(vendor=vendor).order_by("name")


def get_vendor_product(*, user, product_id) -> Product:
    vendor = get_vendor_for_user(user=user)
    return Product.objects.get(vendor=vendor, pk=product_id)


def create_vendor_product(*, user, **fields) -> Product:
    vendor: Vendor = get_vendor_for_user(user=user)
    return Product.objects.create(vendor=vendor, **fields)


def update_vendor_product(*, user, product_id, **fields) -> Product:
    product = get_vendor_product(user=user, product_id=product_id)

    allowed = {"name", "description", "price", "stock", "is_active"}
    update_fields: list[str] = []

    for key, value in fields.items():
        if key not in allowed:
            continue
        setattr(product, key, value)
        update_fields.append(key)

    if update_fields:
        product.save(update_fields=update_fields)

    return product


def delete_vendor_product(*, user, product_id) -> None:
    product = get_vendor_product(user=user, product_id=product_id)
    product.delete()


def list_public_products():
    return Product.objects.filter(is_active=True).order_by("name")


def get_public_product(*, product_id) -> Product:
    return Product.objects.get(pk=product_id, is_active=True)
