"""
Order signals for AgriLink API.
"""
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.utils import timezone
from .models import Order, OrderReview, Payment


@receiver(post_save, sender=Order)
def order_post_save(sender, instance, created, **kwargs):
    """
    Handle order creation and updates.
    """
    if created:
        # Log order creation
        from apps.dashboard.models import UserActivity
        UserActivity.objects.create(
            user=instance.buyer,
            activity_type='ORDER_PLACE',
            description=f"Placed order: {instance.order_number}",
            metadata={
                'order_id': str(instance.id),
                'seller_id': str(instance.seller.id),
                'amount': float(instance.final_amount),
            }
        )

        # Create notification for seller
        from apps.notifications.models import Notification
        Notification.objects.create(
            recipient=instance.seller,
            sender=instance.buyer,
            title=f"New order: {instance.order_number}",
            message=f"{instance.buyer.full_name} placed an order for {instance.product_name}.",
            notification_type=Notification.Type.ORDER_UPDATE,
            related_object_type=Notification.RelatedObjectType.ORDER,
            related_object_id=instance.id,
        )


@receiver(post_save, sender=OrderReview)
def order_review_post_save(sender, instance, created, **kwargs):
    """
    Handle order review creation.
    """
    if created:
        # Create notification for seller
        from apps.notifications.models import Notification
        Notification.objects.create(
            recipient=instance.order.seller,
            sender=instance.reviewer,
            title=f"New review for order {instance.order.order_number}",
            message=f"{instance.reviewer.full_name} left a {instance.overall_rating}-star review.",
            notification_type=Notification.Type.REVIEW,
            related_object_type=Notification.RelatedObjectType.ORDER,
            related_object_id=instance.order.id,
        )


@receiver(post_save, sender=Payment)
def payment_post_save(sender, instance, created, **kwargs):
    """
    Handle payment creation and updates.
    """
    if created:
        # Create notification for order seller
        from apps.notifications.models import Notification
        Notification.objects.create(
            recipient=instance.order.seller,
            sender=instance.order.buyer,
            title=f"Payment received for order {instance.order.order_number}",
            message=f"Payment of {instance.amount} {instance.currency} has been received.",
            notification_type=Notification.Type.PAYMENT,
            related_object_type=Notification.RelatedObjectType.PAYMENT,
            related_object_id=instance.id,
        )