"""
Notification system models for AgriLink.
"""
import uuid
from django.contrib.gis.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.conf import settings

User = get_user_model()


class Notification(models.Model):
    """
    Notification model for user notifications.
    """
    class Type(models.TextChoices):
        ORDER_UPDATE = 'ORDER_UPDATE', 'Order Update'
        MESSAGE = 'MESSAGE', 'Message'
        OFFER = 'OFFER', 'Offer'
        SYSTEM = 'SYSTEM', 'System'
        CONSULTATION = 'CONSULTATION', 'Consultation'
        INQUIRY_RESPONSE = 'INQUIRY_RESPONSE', 'Inquiry Response'
        PAYMENT = 'PAYMENT', 'Payment'
        REVIEW = 'REVIEW', 'Review'
        MARKET_UPDATE = 'MARKET_UPDATE', 'Market Update'
        REMINDER = 'REMINDER', 'Reminder'

    class Priority(models.TextChoices):
        LOW = 'LOW', 'Low'
        NORMAL = 'NORMAL', 'Normal'
        HIGH = 'HIGH', 'High'
        URGENT = 'URGENT', 'Urgent'

    class RelatedObjectType(models.TextChoices):
        ORDER = 'ORDER', 'Order'
        LISTING = 'LISTING', 'Listing'
        CONSULTATION = 'CONSULTATION', 'Consultation'
        INQUIRY = 'INQUIRY', 'Inquiry'
        PAYMENT = 'PAYMENT', 'Payment'
        REVIEW = 'REVIEW', 'Review'
        ADVICE_POST = 'ADVICE_POST', 'Advice Post'
        USER = 'USER', 'User'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications_received')
    sender = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notifications_sent'
    )

    # Content
    title = models.CharField(max_length=200)
    message = models.TextField()
    action_text = models.CharField(max_length=50, blank=True, help_text="Call-to-action button text")
    action_url = models.URLField(blank=True, help_text="URL for action button")

    # Classification
    notification_type = models.CharField(max_length=30, choices=Type.choices, db_index=True)
    priority = models.CharField(max_length=10, choices=Priority.choices, default=Priority.NORMAL)

    # Related object
    related_object_type = models.CharField(
        max_length=20,
        choices=RelatedObjectType.choices,
        blank=True,
        null=True
    )
    related_object_id = models.UUIDField(blank=True, null=True)

    # Status
    is_read = models.BooleanField(default=False, db_index=True)
    read_at = models.DateTimeField(blank=True, null=True)
    is_archived = models.BooleanField(default=False)
    archived_at = models.DateTimeField(blank=True, null=True)

    # Delivery tracking
    email_sent = models.BooleanField(default=False)
    email_sent_at = models.DateTimeField(blank=True, null=True)
    push_sent = models.BooleanField(default=False)
    push_sent_at = models.DateTimeField(blank=True, null=True)
    sms_sent = models.BooleanField(default=False)
    sms_sent_at = models.DateTimeField(blank=True, null=True)

    # Additional data
    metadata = models.JSONField(default=dict, help_text="Additional notification data")
    image_url = models.URLField(blank=True, null=True)

    # Expiration
    expires_at = models.DateTimeField(blank=True, null=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'notifications'
        indexes = [
            models.Index(fields=['recipient', 'is_read']),
            models.Index(fields=['recipient', 'created_at']),
            models.Index(fields=['notification_type']),
            models.Index(fields=['priority']),
            models.Index(fields=['related_object_type', 'related_object_id']),
            models.Index(fields=['expires_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"Notification for {self.recipient.full_name}: {self.title}"

    def mark_as_read(self):
        """
        Mark notification as read.
        """
        if not self.is_read:
            self.is_read = True
            self.read_at = timezone.now()
            self.save(update_fields=['is_read', 'read_at'])

    def mark_as_unread(self):
        """
        Mark notification as unread.
        """
        if self.is_read:
            self.is_read = False
            self.read_at = None
            self.save(update_fields=['is_read', 'read_at'])

    def archive(self):
        """
        Archive the notification.
        """
        if not self.is_archived:
            self.is_archived = True
            self.archived_at = timezone.now()
            self.save(update_fields=['is_archived', 'archived_at'])

    def unarchive(self):
        """
        Unarchive the notification.
        """
        if self.is_archived:
            self.is_archived = False
            self.archived_at = None
            self.save(update_fields=['is_archived', 'archived_at'])

    def is_expired(self):
        """
        Check if notification has expired.
        """
        if self.expires_at:
            return timezone.now() > self.expires_at
        return False

    def send_email(self):
        """
        Mark email as sent.
        """
        self.email_sent = True
        self.email_sent_at = timezone.now()
        self.save(update_fields=['email_sent', 'email_sent_at'])

    def send_push(self):
        """
        Mark push notification as sent.
        """
        self.push_sent = True
        self.push_sent_at = timezone.now()
        self.save(update_fields=['push_sent', 'push_sent_at'])

    def send_sms(self):
        """
        Mark SMS as sent.
        """
        self.sms_sent = True
        self.sms_sent_at = timezone.now()
        self.save(update_fields=['sms_sent', 'sms_sent_at'])


class NotificationPreference(models.Model):
    """
    User notification preferences.
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='notification_preferences')

    # Email preferences
    email_order_updates = models.BooleanField(default=True)
    email_messages = models.BooleanField(default=True)
    email_offers = models.BooleanField(default=True)
    email_system_updates = models.BooleanField(default=True)
    email_consultations = models.BooleanField(default=True)
    email_inquiry_responses = models.BooleanField(default=True)
    email_payments = models.BooleanField(default=True)
    email_reviews = models.BooleanField(default=True)
    email_market_updates = models.BooleanField(default=False)
    email_reminders = models.BooleanField(default=True)

    # Push notification preferences
    push_order_updates = models.BooleanField(default=True)
    push_messages = models.BooleanField(default=True)
    push_offers = models.BooleanField(default=True)
    push_system_updates = models.BooleanField(default=True)
    push_consultations = models.BooleanField(default=True)
    push_inquiry_responses = models.BooleanField(default=True)
    push_payments = models.BooleanField(default=True)
    push_reviews = models.BooleanField(default=True)
    push_market_updates = models.BooleanField(default=True)
    push_reminders = models.BooleanField(default=True)

    # SMS preferences
    sms_order_updates = models.BooleanField(default=False)
    sms_messages = models.BooleanField(default=False)
    sms_offers = models.BooleanField(default=False)
    sms_system_updates = models.BooleanField(default=False)
    sms_consultations = models.BooleanField(default=False)
    sms_inquiry_responses = models.BooleanField(default=False)
    sms_payments = models.BooleanField(default=True)
    sms_reviews = models.BooleanField(default=False)
    sms_market_updates = models.BooleanField(default=False)
    sms_reminders = models.BooleanField(default=False)

    # Frequency settings
    digest_frequency = models.CharField(
        max_length=20,
        choices=[
            ('IMMEDIATE', 'Immediate'),
            ('DAILY', 'Daily Digest'),
            ('WEEKLY', 'Weekly Digest'),
            ('NEVER', 'Never'),
        ],
        default='IMMEDIATE'
    )
    quiet_hours_enabled = models.BooleanField(default=True)
    quiet_hours_start = models.TimeField(default='22:00')
    quiet_hours_end = models.TimeField(default='08:00')

    # Additional preferences
    do_not_disturb = models.BooleanField(default=False)
    do_not_disturb_until = models.DateTimeField(blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'notification_preferences'

    def __str__(self):
        return f"Notification Preferences for {self.user.full_name}"

    def is_in_quiet_hours(self):
        """
        Check if current time is within quiet hours.
        """
        if not self.quiet_hours_enabled or self.do_not_disturb:
            return True

        current_time = timezone.now().time()
        start_time = self.quiet_hours_start
        end_time = self.quiet_hours_end

        if start_time <= end_time:
            return start_time <= current_time <= end_time
        else:
            # Handle overnight quiet hours (e.g., 22:00 to 08:00)
            return current_time >= start_time or current_time <= end_time

    def is_do_not_disturb_active(self):
        """
        Check if do not disturb is currently active.
        """
        if self.do_not_disturb and self.do_not_disturb_until:
            return timezone.now() < self.do_not_disturb_until
        return self.do_not_disturb

    def can_send_notification(self, notification_type, channel='email'):
        """
        Check if a notification can be sent via the specified channel.
        """
        # Check do not disturb
        if self.is_do_not_disturb_active():
            return False

        # Check quiet hours for push and SMS
        if channel in ['push', 'sms'] and self.is_in_quiet_hours():
            return False

        # Check channel-specific preferences
        preference_field = f"{channel}_{notification_type.lower()}"
        return getattr(self, preference_field, False)


class NotificationTemplate(models.Model):
    """
    Templates for system-generated notifications.
    """
    class Type(models.TextChoices):
        ORDER_CREATED = 'ORDER_CREATED', 'Order Created'
        ORDER_CONFIRMED = 'ORDER_CONFIRMED', 'Order Confirmed'
        ORDER_SHIPPED = 'ORDER_SHIPPED', 'Order Shipped'
        ORDER_DELIVERED = 'ORDER_DELIVERED', 'Order Delivered'
        ORDER_CANCELLED = 'ORDER_CANCELLED', 'Order Cancelled'
        PAYMENT_RECEIVED = 'PAYMENT_RECEIVED', 'Payment Received'
        PAYMENT_FAILED = 'PAYMENT_FAILED', 'Payment Failed'
        CONSULTATION_REQUESTED = 'CONSULTATION_REQUESTED', 'Consultation Requested'
        CONSULTATION_CONFIRMED = 'CONSULTATION_CONFIRMED', 'Consultation Confirmed'
        INQUIRY_RECEIVED = 'INQUIRY_RECEIVED', 'Inquiry Received'
        LISTING_CREATED = 'LISTING_CREATED', 'Listing Created'
        LISTING_SOLD = 'LISTING_SOLD', 'Listing Sold'
        REVIEW_RECEIVED = 'REVIEW_RECEIVED', 'Review Received'
        WELCOME = 'WELCOME', 'Welcome'
        PASSWORD_RESET = 'PASSWORD_RESET', 'Password Reset'
        EMAIL_VERIFICATION = 'EMAIL_VERIFICATION', 'Email Verification'

    name = models.CharField(max_length=100, unique=True)
    template_type = models.CharField(max_length=30, choices=Type.choices)

    # Template content
    subject_template = models.CharField(max_length=200, help_text="Email subject template")
    title_template = models.CharField(max_length=200, help_text="Notification title template")
    message_template = models.TextField(help_text="Message template with variables")

    # Action configuration
    action_text_template = models.CharField(max_length=50, blank=True)
    action_url_template = models.CharField(max_length=500, blank=True)

    # Delivery channels
    supports_email = models.BooleanField(default=True)
    supports_push = models.BooleanField(default=True)
    supports_sms = models.BooleanField(default=False)

    # Priority and categorization
    default_priority = models.CharField(
        max_length=10,
        choices=Notification.Priority.choices,
        default=Notification.Priority.NORMAL
    )
    expiration_hours = models.IntegerField(default=72, help_text="Hours before notification expires")

    # Variables documentation
    variables = models.JSONField(
        default=dict,
        help_text="Available variables and their descriptions"
    )

    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'notification_templates'

    def __str__(self):
        return f"{self.name} ({self.template_type})"

    def render_message(self, context):
        """
        Render the message template with provided context.
        """
        from django.template import Template, Context

        template = Template(self.message_template)
        django_context = Context(context)
        return template.render(django_context)

    def render_title(self, context):
        """
        Render the title template with provided context.
        """
        from django.template import Template, Context

        template = Template(self.title_template)
        django_context = Context(context)
        return template.render(django_context)

    def render_subject(self, context):
        """
        Render the subject template with provided context.
        """
        from django.template import Template, Context

        template = Template(self.subject_template)
        django_context = Context(context)
        return template.render(django_context)