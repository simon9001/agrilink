"""
Supplier management models for AgriLink.
"""
import uuid
from django.contrib.gis.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone

User = get_user_model()


class SupplierCategory(models.Model):
    """
    Categories for supplier products and services.
    """
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    icon = models.URLField(blank=True, null=True)
    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'supplier_categories'
        verbose_name_plural = 'Supplier Categories'
        ordering = ['name']

    def __str__(self):
        return self.name


class SupplierProduct(models.Model):
    """
    Products offered by suppliers.
    """
    class ProductType(models.TextChoices):
        PHYSICAL = 'PHYSICAL', 'Physical Product'
        DIGITAL = 'DIGITAL', 'Digital Product'
        SERVICE = 'SERVICE', 'Service'

    class Status(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        INACTIVE = 'INACTIVE', 'Inactive'
        OUT_OF_STOCK = 'OUT_OF_STOCK', 'Out of Stock'
        DISCONTINUED = 'DISCONTINUED', 'Discontinued'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    supplier = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='products',
        limit_choices_to={'role': User.Role.SUPPLIER}
    )

    # Basic information
    name = models.CharField(max_length=200, db_index=True)
    description = models.TextField()
    product_type = models.CharField(max_length=20, choices=ProductType.choices)

    # Categorization
    category = models.ForeignKey(SupplierCategory, on_delete=models.SET_NULL, null=True)
    subcategory = models.CharField(max_length=100, blank=True)
    tags = models.JSONField(default=list, help_text="Product tags for search")

    # Pricing
    unit_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(0)],
        help_text="Price per unit"
    )
    currency = models.CharField(max_length=3, default='USD')
    discount_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    bulk_pricing = models.JSONField(
        default=dict,
        help_text="Bulk pricing tiers"
    )

    # Inventory
    stock_quantity = models.IntegerField(default=0)
    min_order_quantity = models.IntegerField(default=1)
    max_order_quantity = models.IntegerField(blank=True, null=True)
    reorder_level = models.IntegerField(default=0)
    is_unlimited = models.BooleanField(default=False)

    # Specifications
    brand = models.CharField(max_length=100, blank=True)
    model = models.CharField(max_length=100, blank=True)
    specifications = models.JSONField(default=dict, help_text="Product specifications")
    features = models.JSONField(default=list, help_text="Key features")

    # Media
    images = models.JSONField(default=list, help_text="Product image URLs")
    video_url = models.URLField(blank=True, null=True)
    datasheet_url = models.URLField(blank=True, null=True)

    # Shipping and delivery
    weight = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    dimensions = models.JSONField(default=dict, help_text="Length, width, height")
    shipping_required = models.BooleanField(default=True)
    delivery_time_days = models.IntegerField(default=7)
    shipping_regions = models.JSONField(default=list, help_text="Available shipping regions")

    # Status and visibility
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    is_featured = models.BooleanField(default=False)
    is_approved = models.BooleanField(default=True, help_text="Admin approval status")

    # Analytics
    view_count = models.IntegerField(default=0)
    order_count = models.IntegerField(default=0)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    review_count = models.IntegerField(default=0)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'supplier_products'
        indexes = [
            models.Index(fields=['supplier', 'status']),
            models.Index(fields=['category', 'status']),
            models.Index(fields=['name']),
            models.Index(fields=['unit_price']),
            models.Index(fields=['rating']),
            models.Index(fields=['is_featured']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} - {self.supplier.full_name}"

    @property
    def discounted_price(self):
        """
        Calculate price after discount.
        """
        if self.discount_percentage > 0:
            discount_amount = self.unit_price * (self.discount_percentage / 100)
            return self.unit_price - discount_amount
        return self.unit_price

    @property
    def is_in_stock(self):
        """
        Check if product is in stock.
        """
        return self.is_unlimited or self.stock_quantity > 0

    @property
    def is_available(self):
        """
        Check if product is available for purchase.
        """
        return self.status == self.Status.ACTIVE and self.is_in_stock

    def increment_view_count(self):
        """
        Increment view count.
        """
        self.view_count += 1
        self.save(update_fields=['view_count'])

    def update_stock(self, quantity_change):
        """
        Update stock quantity.
        """
        if not self.is_unlimited:
            self.stock_quantity += quantity_change
            if self.stock_quantity <= self.reorder_level and self.stock_quantity > 0:
                # TODO: Send reorder notification
                pass
            self.save(update_fields=['stock_quantity'])


class SupplierService(models.Model):
    """
    Services offered by suppliers.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    supplier = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='services',
        limit_choices_to={'role': User.Role.SUPPLIER}
    )

    # Service details
    name = models.CharField(max_length=200, db_index=True)
    description = models.TextField()
    category = models.ForeignKey(SupplierCategory, on_delete=models.SET_NULL, null=True)

    # Service type and duration
    service_type = models.CharField(
        max_length=50,
        choices=[
            ('CONSULTATION', 'Consultation'),
            ('INSTALLATION', 'Installation'),
            ('MAINTENANCE', 'Maintenance'),
            ('TRAINING', 'Training'),
            ('REPAIR', 'Repair'),
            ('OTHER', 'Other'),
        ]
    )
    estimated_duration_hours = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        help_text="Estimated duration in hours"
    )

    # Pricing
    base_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )
    pricing_model = models.CharField(
        max_length=20,
        choices=[
            ('FIXED', 'Fixed Price'),
            ('HOURLY', 'Hourly Rate'),
            ('PROJECT', 'Project-based'),
            ('PACKAGE', 'Package Deal'),
        ],
        default='FIXED'
    )
    currency = models.CharField(max_length=3, default='USD')

    # Service area
    service_radius_km = models.IntegerField(default=50, help_text="Service radius in kilometers")
    on_site_required = models.BooleanField(default=True)
    remote_available = models.BooleanField(default=False)

    # Requirements and logistics
    requirements = models.JSONField(default=list, help_text="Requirements for the service")
    equipment_provided = models.JSONField(default=list, help_text="Equipment provided by supplier")
    equipment_needed = models.JSONField(default=list, help_text="Equipment needed from client")

    # Availability
    available_days = models.JSONField(default=list, help_text="Days of week available")
    available_hours = models.JSONField(default=dict, help_text="Available hours")
    booking_required = models.BooleanField(default=True)
    booking_advance_days = models.IntegerField(default=3)

    # Status and analytics
    is_active = models.BooleanField(default=True)
    booking_count = models.IntegerField(default=0)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    review_count = models.IntegerField(default=0)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'supplier_services'
        indexes = [
            models.Index(fields=['supplier', 'is_active']),
            models.Index(fields=['category', 'is_active']),
            models.Index(fields=['service_type']),
            models.Index(fields=['rating']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} - {self.supplier.full_name}"


class SupplierInquiry(models.Model):
    """
    Inquiries made by farmers to suppliers about products/services.
    """
    class InquiryType(models.TextChoices):
        PRODUCT = 'PRODUCT', 'Product Inquiry'
        SERVICE = 'SERVICE', 'Service Inquiry'
        GENERAL = 'GENERAL', 'General Inquiry'
        QUOTE = 'QUOTE', 'Price Quote'

    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        RESPONDED = 'RESPONDED', 'Responded'
        IN_PROGRESS = 'IN_PROGRESS', 'In Progress'
        RESOLVED = 'RESOLVED', 'Resolved'
        CLOSED = 'CLOSED', 'Closed'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    supplier = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='inquiries_received',
        limit_choices_to={'role': User.Role.SUPPLIER}
    )
    farmer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='inquiries_sent',
        limit_choices_to={'role': User.Role.FARMER}
    )

    # Inquiry details
    inquiry_type = models.CharField(max_length=20, choices=InquiryType.choices)
    subject = models.CharField(max_length=200)
    message = models.TextField()

    # Related product/service
    related_product = models.ForeignKey(SupplierProduct, on_delete=models.SET_NULL, null=True, blank=True)
    related_service = models.ForeignKey(SupplierService, on_delete=models.SET_NULL, null=True, blank=True)

    # Contact information
    preferred_contact_method = models.CharField(
        max_length=20,
        choices=[
            ('EMAIL', 'Email'),
            ('PHONE', 'Phone'),
            ('WHATSAPP', 'WhatsApp'),
            ('VISIT', 'On-site Visit'),
        ],
        default='EMAIL'
    )
    contact_phone = models.CharField(max_length=20, blank=True)
    farm_location = models.TextField(blank=True, help_text="Farm location for on-site services")

    # Response tracking
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    response_message = models.TextField(blank=True)
    quoted_price = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    estimated_delivery = models.DateField(blank=True, null=True)

    # Priority and urgency
    priority = models.CharField(
        max_length=10,
        choices=[
            ('LOW', 'Low'),
            ('NORMAL', 'Normal'),
            ('HIGH', 'High'),
            ('URGENT', 'Urgent'),
        ],
        default='NORMAL'
    )
    required_by_date = models.DateField(blank=True, null=True)

    # Internal notes
    supplier_notes = models.TextField(blank=True)
    admin_notes = models.TextField(blank=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    responded_at = models.DateTimeField(blank=True, null=True)
    resolved_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'supplier_inquiries'
        indexes = [
            models.Index(fields=['supplier', 'status']),
            models.Index(fields=['farmer', 'status']),
            models.Index(fields=['inquiry_type']),
            models.Index(fields=['priority']),
            models.Index(fields=['created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"Inquiry: {self.subject} ({self.farmer.full_name} → {self.supplier.full_name})"

    def respond(self, message, quoted_price=None, estimated_delivery=None):
        """
        Respond to the inquiry.
        """
        self.status = self.Status.RESPONDED
        self.response_message = message
        self.quoted_price = quoted_price
        self.estimated_delivery = estimated_delivery
        self.responded_at = timezone.now()
        self.save()

    def resolve(self):
        """
        Mark inquiry as resolved.
        """
        self.status = self.Status.RESOLVED
        self.resolved_at = timezone.now()
        self.save()


class SupplierReview(models.Model):
    """
    Reviews for suppliers and their products/services.
    """
    supplier = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='reviews_received',
        limit_choices_to={'role': User.Role.SUPPLIER}
    )
    reviewer = models.ForeignKey(User, on_delete=models.CASCADE)

    # Review subject
    product = models.ForeignKey(SupplierProduct, on_delete=models.SET_NULL, null=True, blank=True)
    service = models.ForeignKey(SupplierService, on_delete=models.SET_NULL, null=True, blank=True)

    # Ratings
    overall_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    quality_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    service_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    value_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )

    # Review content
    title = models.CharField(max_length=200, blank=True)
    comment = models.TextField()

    # Verification
    is_verified_purchase = models.BooleanField(default=False)
    is_helpful_count = models.IntegerField(default=0)

    # Status
    is_public = models.BooleanField(default=True)
    is_approved = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'supplier_reviews'
        indexes = [
            models.Index(fields=['supplier', 'overall_rating']),
            models.Index(fields=['product']),
            models.Index(fields=['service']),
            models.Index(fields=['reviewer']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"Review for {self.supplier.full_name} by {self.reviewer.full_name}"