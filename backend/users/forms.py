from __future__ import annotations

from django import forms
from django.contrib.auth.forms import ReadOnlyPasswordHashField

from .models import User


class UserAdminCreationForm(forms.ModelForm):
    password1 = forms.CharField(label="Password", widget=forms.PasswordInput)
    password2 = forms.CharField(label="Password confirmation", widget=forms.PasswordInput)

    class Meta:
        model = User
        fields = ("phone", "name", "role", "is_active", "is_staff")

    def clean_phone(self):
        return (self.cleaned_data.get("phone") or "").strip()

    def clean(self):
        cleaned = super().clean()
        p1 = cleaned.get("password1")
        p2 = cleaned.get("password2")
        if p1 and p2 and p1 != p2:
            raise forms.ValidationError("Passwords don't match")
        return cleaned

    def save(self, commit=True):
        user = super().save(commit=False)
        user.set_password(self.cleaned_data["password1"])
        if commit:
            user.save()
        return user


class UserAdminChangeForm(forms.ModelForm):
    password = ReadOnlyPasswordHashField(help_text="Raw passwords are not stored.")

    class Meta:
        model = User
        fields = ("phone", "name", "role", "password", "is_active", "is_staff", "is_superuser", "groups", "user_permissions")

    def clean_phone(self):
        return (self.cleaned_data.get("phone") or "").strip()
