"""
Marketplace models for AgriLink.
"""
import uuid
from django.contrib.gis.db import models
from django.contrib.gis.geos import Point
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from core.utils import create_point_from_coordinates

User = get_user_model()


class ProduceCategory(models.Model):
    """
    Product categories for marketplace.
    """
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    icon = models.URLField(blank=True, null=True)
    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'produce_categories'
        verbose_name_plural = 'Produce Categories'
        ordering = ['name']

    def __str__(self):
        return self.name


class ProduceListing(models.Model):
    """
    Produce listings for farmers to sell their products.
    """
    class QualityGrade(models.TextChoices):
        A = 'A', 'Grade A'
        B = 'B', 'Grade B'
        C = 'C', 'Grade C'

    class Status(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        SOLD = 'SOLD', 'Sold'
        EXPIRED = 'EXPIRED', 'Expired'
        DRAFT = 'DRAFT', 'Draft'
        RESERVED = 'RESERVED', 'Reserved'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    farmer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='produce_listings',
        limit_choices_to={'role': User.Role.FARMER}
    )

    # Product information
    product_name = models.CharField(max_length=100, db_index=True)
    category = models.CharField(
        max_length=20,
        choices=[
            ('FRUITS', 'Fruits'),
            ('VEGETABLES', 'Vegetables'),
            ('GRAINS', 'Grains'),
            ('LIVESTOCK', 'Livestock'),
            ('DAIRY', 'Dairy'),
            ('OTHER', 'Other'),
        ],
        db_index=True
    )
    variety = models.CharField(max_length=100, blank=True, null=True)

    # Quantity and pricing
    quantity_available = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0.01)],
        help_text="Quantity available in kg"
    )
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0.01)],
        help_text="Price per kg in USD"
    )
    minimum_order = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=1.0,
        help_text="Minimum order quantity in kg"
    )

    # Quality and certification
    quality_grade = models.CharField(max_length=1, choices=QualityGrade.choices)
    is_organic = models.BooleanField(default=False)
    certification_details = models.JSONField(default=dict, blank=True)

    # Harvest and availability
    harvest_date = models.DateField(help_text="Date of harvest")
    availability_period_start = models.DateField()
    availability_period_end = models.DateField()

    # Location
    location = models.PointField(geography=True, help_text="Product location")
    location_address = models.CharField(max_length=255, blank=True, null=True)

    # Description and media
    description = models.TextField()
    images = models.JSONField(default=list, help_text="List of image URLs")
    video_url = models.URLField(blank=True, null=True)

    # Status and metadata
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    is_featured = models.BooleanField(default=False)
    view_count = models.IntegerField(default=0)
    contact_count = models.IntegerField(default=0)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    expires_at = models.DateTimeField()

    class Meta:
        db_table = 'produce_listings'
        indexes = [
            models.Index(fields=['farmer', 'status']),
            models.Index(fields=['category', 'status']),
            models.Index(fields=['is_organic', 'status']),
            models.Index(fields=['created_at']),
            models.Index(fields=['expires_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.product_name} - {self.farmer.full_name}"

    def save(self, *args, **kwargs):
        # Set expiry date if not provided
        if not self.expires_at:
            self.expires_at = timezone.now() + timezone.timedelta(days=30)
        super().save(*args, **kwargs)

    def set_location(self, latitude, longitude, address=None):
        """
        Set product location from latitude and longitude.
        """
        if latitude is not None and longitude is not None:
            self.location = create_point_from_coordinates(latitude, longitude)
            self.location_address = address
            self.save()

    def get_location_coordinates(self):
        """
        Get latitude and longitude from location Point.
        """
        if self.location:
            return {
                'latitude': self.location.y,
                'longitude': self.location.x
            }
        return None

    @property
    def total_value(self):
        """
        Calculate total value of available produce.
        """
        return self.quantity_available * self.unit_price

    @property
    def is_available(self):
        """
        Check if listing is currently available.
        """
        now = timezone.now()
        return (
            self.status == self.Status.ACTIVE and
            now <= self.expires_at and
            self.availability_period_start <= now.date() <= self.availability_period_end
        )

    def increment_view_count(self):
        """
        Increment view count for the listing.
        """
        self.view_count += 1
        self.save(update_fields=['view_count'])

    def increment_contact_count(self):
        """
        Increment contact count for the listing.
        """
        self.contact_count += 1
        self.save(update_fields=['contact_count'])


class ListingInquiry(models.Model):
    """
    Inquiries made by buyers about produce listings.
    """
    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        RESPONDED = 'RESPONDED', 'Responded'
        CLOSED = 'CLOSED', 'Closed'

    listing = models.ForeignKey(ProduceListing, on_delete=models.CASCADE, related_name='inquiries')
    buyer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        limit_choices_to={'role': User.Role.BUYER}
    )

    message = models.TextField(help_text="Buyer's inquiry message")
    quantity_requested = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    proposed_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        validators=[MinValueValidator(0.01)]
    )

    # Response from farmer
    response_message = models.TextField(blank=True)
    response_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True
    )

    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)

    created_at = models.DateTimeField(auto_now_add=True)
    responded_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'listing_inquiries'
        indexes = [
            models.Index(fields=['listing', 'status']),
            models.Index(fields=['buyer', 'status']),
            models.Index(fields=['created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"Inquiry for {self.listing.product_name} by {self.buyer.full_name}"


class ListingReview(models.Model):
    """
    Reviews for produce listings and farmers.
    """
    listing = models.ForeignKey(ProduceListing, on_delete=models.CASCADE, related_name='reviews')
    reviewer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        limit_choices_to={'role': User.Role.BUYER}
    )

    rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="Rating from 1 to 5"
    )
    comment = models.TextField()

    # Review metrics
    quality_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        default=5
    )
    communication_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        default=5
    )
    delivery_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        default=5
    )

    is_verified_purchase = models.BooleanField(default=False)
    is_helpful_count = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'listing_reviews'
        indexes = [
            models.Index(fields=['listing', 'rating']),
            models.Index(fields=['reviewer']),
        ]
        ordering = ['-created_at']
        unique_together = ['listing', 'reviewer']

    def __str__(self):
        return f"Review for {self.listing.product_name} by {self.reviewer.full_name}"