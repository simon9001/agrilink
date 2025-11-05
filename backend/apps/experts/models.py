"""
Expert services models for AgriLink.
"""
import uuid
from django.contrib.gis.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from django.conf import settings

User = get_user_model()


class AdvicePost(models.Model):
    """
    Advice posts published by agricultural experts.
    """
    class Category(models.TextChoices):
        CROP_MANAGEMENT = 'CROP_MANAGEMENT', 'Crop Management'
        PEST_CONTROL = 'PEST_CONTROL', 'Pest Control'
        IRRIGATION = 'IRRIGATION', 'Irrigation'
        SOIL_HEALTH = 'SOIL_HEALTH', 'Soil Health'
        LIVESTOCK = 'LIVESTOCK', 'Livestock'
        ORGANIC_FARMING = 'ORGANIC_FARMING', 'Organic Farming'
        SUSTAINABLE_AGRICULTURE = 'SUSTAINABLE_AGRICULTURE', 'Sustainable Agriculture'
        MARKET_INSIGHTS = 'MARKET_INSIGHTS', 'Market Insights'
        TECHNOLOGY = 'TECHNOLOGY', 'Technology'

    class TargetAudience(models.TextChoices):
        FARMERS = 'FARMERS', 'Farmers'
        BUYERS = 'BUYERS', 'Buyers'
        SUPPLIERS = 'SUPPLIERS', 'Suppliers'
        ALL = 'ALL', 'All Users'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    expert = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='advice_posts',
        limit_choices_to={'role': User.Role.EXPERT}
    )

    # Content
    title = models.CharField(max_length=200, db_index=True)
    slug = models.SlugField(max_length=250, unique=True)
    content = models.TextField()
    excerpt = models.TextField(max_length=500, help_text="Brief summary of the advice")

    # Categorization
    category = models.CharField(max_length=30, choices=Category.choices, db_index=True)
    target_audience = models.JSONField(default=list, help_text="Target audience for this advice")

    # Media attachments
    featured_image = models.URLField(blank=True, null=True)
    attachments = models.JSONField(default=list, help_text="List of attachment URLs")
    video_url = models.URLField(blank=True, null=True)

    # SEO and metadata
    meta_title = models.CharField(max_length=60, blank=True)
    meta_description = models.CharField(max_length=160, blank=True)
    tags = models.JSONField(default=list, help_text="Tags for searchability")

    # Engagement metrics
    is_featured = models.BooleanField(default=False, db_index=True)
    view_count = models.IntegerField(default=0)
    likes_count = models.IntegerField(default=0)
    shares_count = models.IntegerField(default=0)
    comments_count = models.IntegerField(default=0)

    # Status
    is_draft = models.BooleanField(default=True)
    is_published = models.BooleanField(default=False)
    published_at = models.DateTimeField(blank=True, null=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'advice_posts'
        indexes = [
            models.Index(fields=['expert', 'is_published']),
            models.Index(fields=['category', 'is_published']),
            models.Index(fields=['is_featured', 'published_at']),
            models.Index(fields=['published_at']),
            models.Index(fields=['view_count']),
        ]
        ordering = ['-published_at', '-created_at']

    def __str__(self):
        return f"{self.title} by {self.expert.full_name}"

    def save(self, *args, **kwargs):
        # Generate slug from title if not provided
        if not self.slug:
            from django.utils.text import slugify
            base_slug = slugify(self.title)
            unique_slug = base_slug
            counter = 1
            while AdvicePost.objects.filter(slug=unique_slug).exists():
                unique_slug = f"{base_slug}-{counter}"
                counter += 1
            self.slug = unique_slug

        # Set published timestamp
        if self.is_published and not self.published_at:
            self.published_at = timezone.now()

        super().save(*args, **kwargs)

    def increment_view_count(self):
        """
        Increment view count for the post.
        """
        self.view_count += 1
        self.save(update_fields=['view_count'])

    @property
    def reading_time(self):
        """
        Estimate reading time in minutes.
        """
        word_count = len(self.content.split())
        return max(1, round(word_count / 200))  # Assuming 200 words per minute


class AdvicePostLike(models.Model):
    """
    Likes for advice posts.
    """
    post = models.ForeignKey(AdvicePost, on_delete=models.CASCADE, related_name='likes')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'advice_post_likes'
        unique_together = ['post', 'user']
        indexes = [
            models.Index(fields=['post', 'created_at']),
        ]

    def __str__(self):
        return f"{self.user.full_name} likes {self.post.title}"


class AdvicePostComment(models.Model):
    """
    Comments on advice posts.
    """
    post = models.ForeignKey(AdvicePost, on_delete=models.CASCADE, related_name='comments')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    parent = models.ForeignKey('self', on_delete=models.CASCADE, blank=True, null=True, related_name='replies')

    content = models.TextField()
    is_edited = models.BooleanField(default=False)
    is_approved = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'advice_post_comments'
        indexes = [
            models.Index(fields=['post', 'created_at']),
            models.Index(fields=['user']),
            models.Index(fields=['parent']),
        ]
        ordering = ['created_at']

    def __str__(self):
        return f"Comment by {self.user.full_name} on {self.post.title}"


class Consultation(models.Model):
    """
    Consultation requests between farmers and experts.
    """
    class ConsultationType(models.TextChoices):
        TEXT = 'TEXT', 'Text Chat'
        VIDEO = 'VIDEO', 'Video Call'
        AUDIO = 'AUDIO', 'Audio Call'
        ON_SITE = 'ON_SITE', 'On-site Visit'
        PHONE = 'PHONE', 'Phone Call'

    class Status(models.TextChoices):
        REQUESTED = 'REQUESTED', 'Requested'
        SCHEDULED = 'SCHEDULED', 'Scheduled'
        IN_PROGRESS = 'IN_PROGRESS', 'In Progress'
        COMPLETED = 'COMPLETED', 'Completed'
        CANCELLED = 'CANCELLED', 'Cancelled'
        NO_SHOW = 'NO_SHOW', 'No Show'

    class PaymentStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        PAID = 'PAID', 'Paid'
        REFUNDED = 'REFUNDED', 'Refunded'
        CANCELLED = 'CANCELLED', 'Cancelled'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    expert = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='expert_consultations',
        limit_choices_to={'role': User.Role.EXPERT}
    )
    farmer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='farmer_consultations',
        limit_choices_to={'role': User.Role.FARMER}
    )

    # Consultation details
    topic = models.CharField(max_length=200, db_index=True)
    description = models.TextField()
    consultation_type = models.CharField(max_length=20, choices=ConsultationType.choices)

    # Scheduling
    scheduled_date = models.DateTimeField()
    duration_minutes = models.IntegerField(default=60)
    timezone = models.CharField(max_length=50, default='UTC')

    # Location/Platform
    meeting_url = models.URLField(blank=True, null=True, help_text="Video call link")
    meeting_address = models.TextField(blank=True, help_text="Physical address for on-site visits")
    meeting_phone = models.CharField(max_length=20, blank=True, help_text="Phone number for calls")

    # Status tracking
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.REQUESTED)
    payment_status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING)

    # Payment details
    consultation_rate = models.DecimalField(max_digits=10, decimal_places=2, help_text="Rate per hour")
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')

    # Meeting details
    actual_start_time = models.DateTimeField(blank=True, null=True)
    actual_end_time = models.DateTimeField(blank=True, null=True)
    actual_duration_minutes = models.IntegerField(blank=True, null=True)

    # Notes and outcomes
    expert_notes = models.TextField(blank=True, help_text="Private notes for expert")
    farmer_notes = models.TextField(blank=True, help_text="Private notes for farmer")
    shared_notes = models.TextField(blank=True, help_text="Notes shared with both parties")
    recommendations = models.JSONField(default=list, help_text="Recommendations provided")

    # Attachments and resources
    attachments = models.JSONField(default=list, help_text="Files shared during consultation")
    resources = models.JSONField(default=list, help_text="Recommended resources")

    # Follow-up
    follow_up_required = models.BooleanField(default=False)
    follow_up_date = models.DateTimeField(blank=True, null=True)
    follow_up_notes = models.TextField(blank=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(blank=True, null=True)
    cancelled_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'consultations'
        indexes = [
            models.Index(fields=['expert', 'status']),
            models.Index(fields=['farmer', 'status']),
            models.Index(fields=['scheduled_date']),
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['consultation_type']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"Consultation: {self.topic} ({self.expert.full_name} - {self.farmer.full_name})"

    def save(self, *args, **kwargs):
        # Calculate total amount if not provided
        if not self.total_amount and self.consultation_rate:
            hours = self.duration_minutes / 60
            self.total_amount = self.consultation_rate * hours

        super().save(*args, **kwargs)

    def start_consultation(self):
        """
        Mark consultation as in progress.
        """
        if self.status == self.Status.SCHEDULED:
            self.status = self.Status.IN_PROGRESS
            self.actual_start_time = timezone.now()
            self.save()

    def complete_consultation(self, notes=None, recommendations=None):
        """
        Mark consultation as completed.
        """
        if self.status == self.Status.IN_PROGRESS:
            self.status = self.Status.COMPLETED
            self.actual_end_time = timezone.now()
            self.completed_at = timezone.now()

            # Calculate actual duration
            if self.actual_start_time:
                duration = self.actual_end_time - self.actual_start_time
                self.actual_duration_minutes = int(duration.total_seconds() / 60)

            # Update notes and recommendations if provided
            if notes:
                self.shared_notes = notes
            if recommendations:
                self.recommendations = recommendations

            self.save()

    def cancel_consultation(self, reason="", cancelled_by='farmer'):
        """
        Cancel the consultation.
        """
        if self.status not in [self.Status.COMPLETED, self.Status.CANCELLED]:
            self.status = self.Status.CANCELLED
            self.cancelled_at = timezone.now()
            self.shared_notes = f"Cancelled by {cancelled_by}: {reason}"
            self.save()

    @property
    def is_upcoming(self):
        """
        Check if consultation is scheduled for the future.
        """
        return self.status == self.Status.SCHEDULED and self.scheduled_date > timezone.now()

    @property
    def is_past_due(self):
        """
        Check if consultation time has passed.
        """
        return self.scheduled_date < timezone.now() and self.status not in [
            self.Status.COMPLETED, self.Status.CANCELLED
        ]


class ConsultationReview(models.Model):
    """
    Reviews for completed consultations.
    """
    consultation = models.OneToOneField(Consultation, on_delete=models.CASCADE, related_name='review')
    reviewer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        limit_choices_to={'role': User.Role.FARMER}
    )

    # Ratings
    overall_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    expertise_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    communication_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    helpfulness_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )

    # Review content
    title = models.CharField(max_length=200, blank=True)
    comment = models.TextField()

    # Recommendations
    would_recommend = models.BooleanField(default=True)
    would_consult_again = models.BooleanField(default=True)

    # Metadata
    is_public = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'consultation_reviews'
        indexes = [
            models.Index(fields=['consultation']),
            models.Index(fields=['reviewer']),
            models.Index(fields=['overall_rating']),
        ]

    def __str__(self):
        return f"Review for consultation {self.consultation.id} by {self.reviewer.full_name}"