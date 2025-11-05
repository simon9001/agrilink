"""
Authentication signals for AgriLink API.
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from .utils import send_verification_email, get_or_create_notification_preferences

User = get_user_model()


@receiver(post_save, sender=User)
def user_post_save(sender, instance, created, **kwargs):
    """
    Handle user creation and updates.
    """
    if created:
        # Create notification preferences for new users
        get_or_create_notification_preferences(instance)

        # Send verification email for new users
        if not instance.is_verified:
            send_verification_email(instance)