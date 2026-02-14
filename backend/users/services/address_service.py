from __future__ import annotations

from django.db import transaction

from users.models import Address, User


def list_addresses(*, user: User):
    return Address.objects.filter(user=user).order_by("-is_default", "-updated_at")


def get_address(*, user: User, address_id: int) -> Address:
    return Address.objects.get(user=user, id=address_id)


@transaction.atomic
def create_address(*, user: User, **fields) -> Address:
    is_default = bool(fields.pop("is_default", False))

    # Lock this user's addresses to prevent concurrent default races.
    qs = Address.objects.select_for_update().filter(user=user)
    had_existing = qs.exists()

    if is_default:
        qs.filter(is_default=True).update(is_default=False)

    address = Address.objects.create(user=user, is_default=is_default, **fields)

    # If it's the first address, make it default.
    if not had_existing:
        if not address.is_default:
            address.is_default = True
            address.save(update_fields=["is_default"])

    return address


@transaction.atomic
def update_address(*, user: User, address_id: int, **fields) -> Address:
    address = Address.objects.select_for_update().get(user=user, id=address_id)

    is_default = fields.pop("is_default", None)

    allowed_fields = {
        "label",
        "receiver_name",
        "receiver_phone",
        "line1",
        "line2",
        "landmark",
        "city",
        "state",
        "pincode",
    }

    update_fields: list[str] = []

    for k, v in fields.items():
        if k not in allowed_fields:
            continue
        setattr(address, k, v)
        update_fields.append(k)

    if update_fields:
        address.save(update_fields=update_fields)

    if is_default is True:
        set_default_address(user=user, address_id=address.id)
        address.refresh_from_db()
    elif is_default is False:
        if address.is_default:
            address.is_default = False
            address.save(update_fields=["is_default"])
        address.refresh_from_db()

    return address


@transaction.atomic
def delete_address(*, user: User, address_id: int) -> None:
    address = get_address(user=user, address_id=address_id)
    was_default = address.is_default
    address.delete()

    if was_default:
        remaining = Address.objects.filter(user=user).order_by("-updated_at").first()
        if remaining:
            Address.objects.filter(user=user, is_default=True).update(is_default=False)
            remaining.is_default = True
            remaining.save(update_fields=["is_default"])


@transaction.atomic
def set_default_address(*, user: User, address_id: int) -> Address:
    address = get_address(user=user, address_id=address_id)
    Address.objects.filter(user=user, is_default=True).exclude(id=address.id).update(is_default=False)
    if not address.is_default:
        address.is_default = True
        address.save(update_fields=["is_default"])
    return address
