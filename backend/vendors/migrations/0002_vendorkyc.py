from __future__ import annotations

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("vendors", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="VendorKyc",
            fields=[
                ("id", models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("id_front_path", models.CharField(blank=True, max_length=500)),
                ("id_back_path", models.CharField(blank=True, max_length=500)),
                ("shop_license_path", models.CharField(blank=True, max_length=500)),
                ("selfie_path", models.CharField(blank=True, max_length=500)),
                (
                    "status",
                    models.CharField(
                        choices=[("pending", "Pending"), ("approved", "Approved"), ("rejected", "Rejected")],
                        default="pending",
                        max_length=20,
                    ),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "vendor",
                    models.OneToOneField(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="kyc",
                        to="vendors.vendor",
                    ),
                ),
            ],
        ),
    ]
