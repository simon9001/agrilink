"""
Marketplace signals for AgriLink API.
"""
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.utils import timezone
from .models import ProduceListing, ListingInquiry, ListingReview


@receiver(post_save, sender=ProduceListing)
def produce_listing_post_save(sender, instance, created, **kwargs):
    """
    Handle produce listing creation and updates.
    """
    if created:
        # Log listing creation
        from apps.dashboard.models import UserActivity
        UserActivity.objects.create(
            user=instance.farmer,
            activity_type='LISTING_CREATE',
            description=f"Created listing: {instance.product_name}",
            metadata={
                'listing_id': str(instance.id),
                'category': instance.category,
                'quantity': float(instance.quantity_available),
                'price': float(instance.unit_price),
            }
        )


@receiver(post_save, sender=ListingInquiry)
def listing_inquiry_post_save(sender, instance, created, **kwargs):
    """
    Handle listing inquiry creation.
    """
    if created:
        # Create notification for farmer
        from apps.notifications.models import Notification
        Notification.objects.create(
            recipient=instance.listing.farmer,
            sender=instance.buyer,
            title=f"New inquiry for {instance.listing.product_name}",
            message=f"{instance.buyer.full_name} is interested in your listing.",
            notification_type=Notification.Type.INQUIRY_RESPONSE,
            related_object_type=Notification.RelatedObjectType.LISTING,
            related_object_id=instance.listing.id,
        )


@receiver(post_save, sender=ListingReview)
def listing_review_post_save(sender, instance, created, **kwargs):
    """
    Handle listing review creation.
    """
    if created:
        # Create notification for farmer
        from apps.notifications.models import Notification
        Notification.objects.create(
            recipient=instance.listing.farmer,
            sender=instance.reviewer,
            title=f"New review for {instance.listing.product_name}",
            message=f"{instance.reviewer.full_name} left a {instance.rating}-star review.",
            notification_type=Notification.Type.REVIEW,
            related_object_type=Notification.RelatedObjectType.LISTING,
            related_object_id=instance.listing.id,
        )