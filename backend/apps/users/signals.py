"""
User signals for AgriLink API.
"""
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from apps.dashboard.models import UserActivity
from apps.notifications.models import NotificationPreference

User = get_user_model()


@receiver(post_save, sender=User)
def user_post_save(sender, instance, created, **kwargs):
    """
    Handle user creation and updates.
    """
    if created:
        # Create notification preferences for new users
        NotificationPreference.objects.get_or_create(user=instance)


@receiver(post_delete, sender=User)
def user_post_delete(sender, instance, **kwargs):
    """
    Handle user deletion (soft delete activities).
    """
    # Log user deletion
    UserActivity.objects.create(
        user=instance,
        activity_type='SYSTEM',
        description=f"User account deleted: {instance.email}",
        metadata={'deleted_at': instance.deleted_at if hasattr(instance, 'deleted_at') else None}
    )