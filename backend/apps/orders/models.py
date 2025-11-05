"""
Order models for AgriLink.
"""
import uuid
from django.contrib.gis.db import models
from django.contrib.gis.geos import Point
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator
from django.utils import timezone
from core.utils import generate_order_number, create_point_from_coordinates

User = get_user_model()


class Order(models.Model):
    """
    Order model for transactions between buyers and farmers.
    """
    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        CONFIRMED = 'CONFIRMED', 'Confirmed'
        PROCESSING = 'PROCESSING', 'Processing'
        SHIPPED = 'SHIPPED', 'Shipped'
        DELIVERED = 'DELIVERED', 'Delivered'
        CANCELLED = 'CANCELLED', 'Cancelled'
        REFUNDED = 'REFUNDED', 'Refunded'

    class PaymentStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        PAID = 'PAID', 'Paid'
        PARTIALLY_PAID = 'PARTIALLY_PAID', 'Partially Paid'
        REFUNDED = 'REFUNDED', 'Refunded'
        FAILED = 'FAILED', 'Failed'

    class PaymentMethod(models.TextChoices):
        CASH = 'CASH', 'Cash on Delivery'
        TRANSFER = 'TRANSFER', 'Bank Transfer'
        MOBILE_MONEY = 'MOBILE_MONEY', 'Mobile Money'
        CREDIT_CARD = 'CREDIT_CARD', 'Credit Card'
        ESCROW = 'ESCROW', 'Escrow'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order_number = models.CharField(max_length=50, unique=True, editable=False)

    # Participants
    buyer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='purchase_orders',
        limit_choices_to={'role': User.Role.BUYER}
    )
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sales_orders',
        limit_choices_to={'role': User.Role.FARMER}
    )

    # Listing reference
    listing = models.ForeignKey(
        'marketplace.ProduceListing',
        on_delete=models.SET_NULL,
        null=True,
        related_name='orders'
    )

    # Order details
    product_name = models.CharField(max_length=100)
    product_description = models.TextField(blank=True)
    quantity_ordered = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    total_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )

    # Delivery information
    delivery_location = models.PointField(geography=True)
    delivery_address = models.CharField(max_length=500)
    delivery_date = models.DateField()
    delivery_instructions = models.TextField(blank=True)

    # Order status
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    payment_status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING)
    payment_method = models.CharField(max_length=20, choices=PaymentMethod.choices, default=PaymentMethod.CASH)

    # Additional costs
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    service_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    tax_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    final_amount = models.DecimalField(max_digits=15, decimal_places=2)

    # Notes and communication
    buyer_notes = models.TextField(blank=True)
    seller_notes = models.TextField(blank=True)
    admin_notes = models.TextField(blank=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    confirmed_at = models.DateTimeField(blank=True, null=True)
    shipped_at = models.DateTimeField(blank=True, null=True)
    delivered_at = models.DateTimeField(blank=True, null=True)
    cancelled_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'orders'
        indexes = [
            models.Index(fields=['buyer', 'status']),
            models.Index(fields=['seller', 'status']),
            models.Index(fields=['order_number']),
            models.Index(fields=['created_at']),
            models.Index(fields=['delivery_date']),
            models.Index(fields=['payment_status']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"Order {self.order_number} - {self.buyer.full_name}"

    def save(self, *args, **kwargs):
        # Generate order number if not provided
        if not self.order_number:
            self.order_number = generate_order_number()

        # Calculate final amount
        self.final_amount = (
            self.total_amount +
            self.delivery_fee +
            self.service_fee +
            self.tax_amount
        )

        super().save(*args, **kwargs)

    def set_delivery_location(self, latitude, longitude, address=None):
        """
        Set delivery location from latitude and longitude.
        """
        if latitude is not None and longitude is not None:
            self.delivery_location = create_point_from_coordinates(latitude, longitude)
            self.delivery_address = address or self.delivery_address
            self.save()

    def get_delivery_location_coordinates(self):
        """
        Get latitude and longitude from delivery location Point.
        """
        if self.delivery_location:
            return {
                'latitude': self.delivery_location.y,
                'longitude': self.delivery_location.x
            }
        return None

    def confirm_order(self):
        """
        Confirm the order and update timestamps.
        """
        if self.status == self.Status.PENDING:
            self.status = self.Status.CONFIRMED
            self.confirmed_at = timezone.now()
            self.save()

    def ship_order(self):
        """
        Mark order as shipped.
        """
        if self.status in [self.Status.CONFIRMED, self.Status.PROCESSING]:
            self.status = self.Status.SHIPPED
            self.shipped_at = timezone.now()
            self.save()

    def deliver_order(self):
        """
        Mark order as delivered.
        """
        if self.status == self.Status.SHIPPED:
            self.status = self.Status.DELIVERED
            self.delivered_at = timezone.now()
            self.save()

    def cancel_order(self, reason=""):
        """
        Cancel the order.
        """
        if self.status not in [self.Status.DELIVERED, self.Status.CANCELLED, self.Status.REFUNDED]:
            self.status = self.Status.CANCELLED
            self.cancelled_at = timezone.now()
            if reason:
                self.admin_notes = reason
            self.save()

    @property
    def is_active(self):
        """
        Check if order is in active state.
        """
        return self.status not in [self.Status.DELIVERED, self.Status.CANCELLED, self.Status.REFUNDED]

    @property
    def can_be_cancelled(self):
        """
        Check if order can be cancelled.
        """
        return self.status in [self.Status.PENDING, self.Status.CONFIRMED]


class OrderItem(models.Model):
    """
    Individual items within an order (for future multi-item orders).
    """
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    product_name = models.CharField(max_length=100)
    quantity = models.DecimalField(max_digits=15, decimal_places=2)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    total_price = models.DecimalField(max_digits=15, decimal_places=2)

    # Product details
    product_image = models.URLField(blank=True, null=True)
    product_description = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'order_items'

    def __str__(self):
        return f"{self.product_name} - {self.order.order_number}"


class OrderTracking(models.Model):
    """
    Order tracking information.
    """
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='tracking_updates')

    # Tracking details
    status = models.CharField(max_length=20, choices=Order.Status.choices)
    location = models.PointField(geography=True, blank=True, null=True)
    location_description = models.CharField(max_length=255, blank=True)

    # Tracking information
    tracking_number = models.CharField(max_length=100, blank=True)
    carrier_name = models.CharField(max_length=100, blank=True)
    estimated_delivery = models.DateTimeField(blank=True, null=True)

    # Notes
    notes = models.TextField(blank=True)
    internal_notes = models.TextField(blank=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'order_tracking'
        indexes = [
            models.Index(fields=['order', 'created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"Tracking for {self.order.order_number} - {self.status}"


class OrderReview(models.Model):
    """
    Reviews for completed orders.
    """
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='review')
    reviewer = models.ForeignKey(User, on_delete=models.CASCADE)

    # Overall rating
    rating = models.IntegerField(
        validators=[MinValueValidator(1)],
        help_text="Rating from 1 to 5"
    )

    # Detailed ratings
    product_quality = models.IntegerField(
        validators=[MinValueValidator(1)],
        default=5
    )
    delivery_speed = models.IntegerField(
        validators=[MinValueValidator(1)],
        default=5
    )
    communication = models.IntegerField(
        validators=[MinValueValidator(1)],
        default=5
    )
    packaging = models.IntegerField(
        validators=[MinValueValidator(1)],
        default=5
    )

    # Review content
    title = models.CharField(max_length=200, blank=True)
    comment = models.TextField()

    # Review metadata
    is_public = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False)
    helpful_count = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'order_reviews'
        indexes = [
            models.Index(fields=['order']),
            models.Index(fields=['reviewer', 'rating']),
        ]

    def __str__(self):
        return f"Review for {self.order.order_number} by {self.reviewer.full_name}"


class Payment(models.Model):
    """
    Payment records for orders.
    """
    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        PROCESSING = 'PROCESSING', 'Processing'
        COMPLETED = 'COMPLETED', 'Completed'
        FAILED = 'FAILED', 'Failed'
        REFUNDED = 'REFUNDED', 'Refunded'
        CANCELLED = 'CANCELLED', 'Cancelled'

    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='payments')

    # Payment details
    payment_method = models.CharField(max_length=20, choices=Order.PaymentMethod.choices)
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')

    # Transaction information
    transaction_id = models.CharField(max_length=100, unique=True, blank=True, null=True)
    gateway = models.CharField(max_length=50, help_text="Payment gateway used")
    gateway_response = models.JSONField(default=dict, blank=True)

    # Status and timestamps
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    processed_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Refund information
    refund_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    refund_reason = models.TextField(blank=True)
    refunded_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'payments'
        indexes = [
            models.Index(fields=['order', 'status']),
            models.Index(fields=['transaction_id']),
            models.Index(fields=['created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"Payment for {self.order.order_number} - {self.amount} {self.currency}"