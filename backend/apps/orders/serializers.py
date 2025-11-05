"""
Order management serializers for AgriLink API.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.gis.geos import Point
from django.utils import timezone
from core.utils import create_point_from_coordinates, format_currency, format_date
from core.exceptions import ValidationException, NotFoundException
from .models import Order, OrderItem, OrderTracking, OrderReview, Payment

User = get_user_model()


class OrderItemSerializer(serializers.ModelSerializer):
    """
    Serializer for individual order items.
    """
    product_name = serializers.CharField(read_only=True)
    formatted_price = serializers.SerializerMethodField()
    formatted_total = serializers.SerializerMethodField()

    class Meta:
        model = OrderItem
        fields = [
            'id', 'product_name', 'quantity', 'unit_price',
            'formatted_price', 'total_price', 'formatted_total',
            'product_image', 'product_description', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']

    def get_formatted_price(self, obj):
        """
        Format unit price as currency.
        """
        return format_currency(obj.unit_price)

    def get_formatted_total(self, obj):
        """
        Format total price as currency.
        """
        return format_currency(obj.total_price)

    def validate_quantity(self, value):
        """
        Validate item quantity.
        """
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than 0")
        return value

    def validate_unit_price(self, value):
        """
        Validate unit price.
        """
        if value <= 0:
            raise serializers.ValidationError("Unit price must be greater than 0")
        return value


class OrderSerializer(serializers.ModelSerializer):
    """
    Base serializer for orders.
    """
    buyer_name = serializers.CharField(source='buyer.full_name', read_only=True)
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    product_name = serializers.CharField(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)

    # Formatted fields
    formatted_total_amount = serializers.SerializerMethodField()
    formatted_final_amount = serializers.SerializerMethodField()
    formatted_delivery_fee = serializers.SerializerMethodField()
    formatted_service_fee = serializers.SerializerMethodField()

    # Location fields
    delivery_coordinates = serializers.SerializerMethodField()

    # Timestamps
    formatted_created_at = serializers.SerializerMethodField()
    formatted_delivery_date = serializers.SerializerMethodField()

    # Order items
    items = OrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'buyer', 'buyer_name', 'seller', 'seller_name',
            'listing', 'product_name', 'quantity_ordered', 'unit_price',
            'total_amount', 'formatted_total_amount',
            'delivery_location', 'delivery_coordinates', 'delivery_address',
            'delivery_date', 'formatted_delivery_date',
            'delivery_instructions',
            'status', 'status_display', 'payment_status', 'payment_status_display',
            'payment_method', 'payment_method_display',
            'delivery_fee', 'formatted_delivery_fee',
            'service_fee', 'formatted_service_fee',
            'tax_amount', 'final_amount', 'formatted_final_amount',
            'buyer_notes', 'seller_notes', 'admin_notes',
            'formatted_created_at', 'confirmed_at', 'shipped_at',
            'delivered_at', 'cancelled_at', 'items'
        ]

    def get_formatted_total_amount(self, obj):
        """
        Format total amount as currency.
        """
        return format_currency(obj.total_amount)

    def get_formatted_final_amount(self, obj):
        """
        Format final amount as currency.
        """
        return format_currency(obj.final_amount)

    def get_formatted_delivery_fee(self, obj):
        """
        Format delivery fee as currency.
        """
        return format_currency(obj.delivery_fee)

    def get_formatted_service_fee(self, obj):
        """
        Format service fee as currency.
        """
        return format_currency(obj.service_fee)

    def get_delivery_coordinates(self, obj):
        """
        Get delivery coordinates for display.
        """
        return obj.get_delivery_location_coordinates()

    def get_formatted_created_at(self, obj):
        """
        Get formatted creation date.
        """
        return format_date(obj.created_at, '%B %d, %Y at %I:%M %p')

    def get_formatted_delivery_date(self, obj):
        """
        Get formatted delivery date.
        """
        return format_date(obj.delivery_date, '%B %d, %Y')

    def validate_quantity_ordered(self, value):
        """
        Validate ordered quantity.
        """
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than 0")
        return value

    def validate_unit_price(self, value):
        """
        Validate unit price.
        """
        if value <= 0:
            raise serializers.ValidationError("Unit price must be greater than 0")
        return value

    def validate_delivery_date(self, value):
        """
        Validate delivery date.
        """
        if value < timezone.now().date():
            raise serializers.ValidationError("Delivery date cannot be in the past")
        return value

    def validate_delivery_fee(self, value):
        """
        Validate delivery fee.
        """
        if value < 0:
            raise serializers.ValidationError("Delivery fee cannot be negative")
        return value

    def validate_service_fee(self, value):
        """
        Validate service fee.
        """
        if value < 0:
            raise serializers.ValidationError("Service fee cannot be negative")
        return value

    def validate_tax_amount(self, value):
        """
        Validate tax amount.
        """
        if value < 0:
            raise serializers.ValidationError("Tax amount cannot be negative")
        return value


class OrderCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating new orders.
    """
    buyer = serializers.HiddenField(default=serializers.CurrentUserDefault())
    items = OrderItemSerializer(many=True, required=False)

    class Meta:
        model = Order
        fields = [
            'buyer', 'listing', 'product_name', 'product_description',
            'quantity_ordered', 'unit_price', 'delivery_location',
            'delivery_address', 'delivery_date', 'delivery_instructions',
            'payment_method', 'buyer_notes', 'items'
        ]

    def validate_listing(self, value):
        """
        Validate that listing exists and is available.
        """
        if not value:
            raise serializers.ValidationError("Listing is required")

        if not value.is_available:
            raise serializers.ValidationError("This listing is not available for ordering")

        # Check if user is trying to order their own listing
        if self.context['request'].user == value.farmer:
            raise serializers.ValidationError("You cannot order your own listing")

        return value

    def validate_quantity_ordered(self, value):
        """
        Validate ordered quantity against listing availability.
        """
        listing = self.initial_data.get('listing')
        if listing and hasattr(listing, 'quantity_available'):
            if value > listing.quantity_available:
                raise serializers.ValidationError(
                    f"Ordered quantity ({value} kg) exceeds available quantity ({listing.quantity_available} kg)"
                )

            if value < listing.minimum_order:
                raise serializers.ValidationError(
                    f"Ordered quantity ({value} kg) is below minimum order ({listing.minimum_order} kg)"
                )

        return value

    def validate(self, attrs):
        """
        Cross-field validation.
        """
        listing = attrs.get('listing')
        quantity = attrs.get('quantity_ordered')

        if listing and quantity:
            # Check if delivery date is reasonable
            delivery_date = attrs.get('delivery_date')
            if delivery_date:
                availability_end = listing.availability_period_end
                if availability_end and delivery_date > availability_end:
                    raise serializers.ValidationError(
                        f"Delivery date must be within listing availability period (until {availability_end})"
                    )

            # Set unit price from listing if not provided
            if 'unit_price' not in attrs or attrs['unit_price'] is None:
                attrs['unit_price'] = listing.unit_price

            # Set product details from listing
            attrs['product_name'] = listing.product_name
            attrs['product_description'] = listing.description[:500]  # Truncate if too long

        return attrs

    def create(self, validated_data):
        """
        Create order with automatic calculations.
        """
        items_data = validated_data.pop('items', [])

        # Get listing information
        listing = validated_data['listing']
        validated_data['seller'] = listing.farmer

        # Calculate total amount
        quantity = validated_data['quantity_ordered']
        unit_price = validated_data['unit_price']
        validated_data['total_amount'] = quantity * unit_price

        # Set default fees (these would be calculated based on business rules)
        validated_data['delivery_fee'] = 0  # Calculate based on distance/weight
        validated_data['service_fee'] = validated_data['total_amount'] * 0.05  # 5% service fee
        validated_data['tax_amount'] = 0  # Calculate based on local tax rules

        # Calculate final amount
        validated_data['final_amount'] = (
            validated_data['total_amount'] +
            validated_data['delivery_fee'] +
            validated_data['service_fee'] +
            validated_data['tax_amount']
        )

        # Create order
        order = Order.objects.create(**validated_data)

        # Create order items if provided
        if items_data:
            for item_data in items_data:
                OrderItem.objects.create(order=order, **item_data)

        # Update listing quantity
        listing.quantity_available -= quantity
        listing.save(update_fields=['quantity_available'])

        return order


class OrderDetailSerializer(OrderSerializer):
    """
    Detailed serializer for order information.
    """
    tracking_updates = serializers.SerializerMethodField()
    payments = serializers.SerializerMethodField()
    review = serializers.SerializerMethodField()

    class Meta(OrderSerializer.Meta):
        fields = OrderSerializer.Meta.fields + [
            'tracking_updates', 'payments', 'review'
        ]

    def get_tracking_updates(self, obj):
        """
        Get tracking updates for the order.
        """
        tracking = obj.tracking_updates.all().order_by('-created_at')
        return [
            {
                'id': str(t.id),
                'status': t.status,
                'location_description': t.location_description,
                'notes': t.notes,
                'created_at': format_date(t.created_at, '%B %d, %Y at %I:%M %p'),
            }
            for t in tracking
        ]

    def get_payments(self, obj):
        """
        Get payment information for the order.
        """
        payments = obj.payments.all().order_by('-created_at')
        return [
            {
                'id': str(p.id),
                'amount': format_currency(p.amount),
                'status': p.status,
                'method': p.payment_method,
                'created_at': format_date(p.created_at, '%B %d, %Y'),
            }
            for p in payments
        ]

    def get_review(self, obj):
        """
        Get review for the order if available.
        """
        try:
            review = obj.review
            return {
                'id': str(review.id),
                'rating': review.overall_rating,
                'comment': review.comment,
                'created_at': format_date(review.created_at, '%B %d, %Y'),
            }
        except OrderReview.DoesNotExist:
            return None


class OrderStatusUpdateSerializer(serializers.Serializer):
    """
    Serializer for updating order status.
    """
    new_status = serializers.ChoiceField(choices=Order.Status.choices)
    notes = serializers.CharField(required=False, allow_blank=True)
    tracking_number = serializers.CharField(required=False, allow_blank=True)
    carrier_name = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        """
        Validate status transition.
        """
        new_status = attrs['new_status']
        order = self.context['order']

        # Validate status transitions based on current status
        valid_transitions = {
            Order.Status.PENDING: [Order.Status.CONFIRMED, Order.Status.CANCELLED],
            Order.Status.CONFIRMED: [Order.Status.PROCESSING, Order.Status.CANCELLED],
            Order.Status.PROCESSING: [Order.Status.SHIPPED, Order.Status.CANCELLED],
            Order.Status.SHIPPED: [Order.Status.DELIVERED],
            Order.Status.DELIVERED: [],  # Terminal state
            Order.Status.CANCELLED: [],  # Terminal state
        }

        current_status = order.status
        if new_status not in valid_transitions.get(current_status, []):
            raise serializers.ValidationError(
                f"Cannot transition from {current_status} to {new_status}"
            )

        # Require notes for cancellation
        if new_status == Order.Status.CANCELLED and not attrs.get('notes'):
            raise serializers.ValidationError("Notes are required when cancelling an order")

        return attrs


class OrderPaymentSerializer(serializers.ModelSerializer):
    """
    Serializer for processing order payments.
    """
    class Meta:
        model = Payment
        fields = [
            'payment_method', 'transaction_id', 'gateway',
            'amount', 'currency'
        ]

    def validate_amount(self, value):
        """
        Validate payment amount matches order final amount.
        """
        order = self.context['order']
        if value != order.final_amount:
            raise serializers.ValidationError(
                f"Payment amount ({value}) must match order final amount ({order.final_amount})"
            )
        return value

    def validate_payment_method(self, value):
        """
        Validate payment method matches order payment method.
        """
        order = self.context['order']
        if value != order.payment_method:
            raise serializers.ValidationError(
                f"Payment method ({value}) must match order payment method ({order.payment_method})"
            )
        return value

    def create(self, validated_data):
        """
        Create payment and update order status.
        """
        order = self.context['order']

        # Create payment record
        payment = Payment.objects.create(
            order=order,
            status=Payment.Status.PROCESSING,
            **validated_data
        )

        # Update order payment status
        order.payment_status = Order.PaymentStatus.PROCESSING
        order.save(update_fields=['payment_status'])

        return payment


class OrderReviewSerializer(serializers.ModelSerializer):
    """
    Serializer for creating order reviews.
    """
    reviewer_name = serializers.CharField(source='reviewer.full_name', read_only=True)
    formatted_date = serializers.SerializerMethodField()

    class Meta:
        model = OrderReview
        fields = [
            'id', 'reviewer', 'reviewer_name', 'order',
            'overall_rating', 'quality_rating', 'delivery_speed',
            'communication', 'packaging',
            'title', 'comment', 'would_recommend',
            'would_consult_again', 'is_public', 'is_verified',
            'formatted_date', 'created_at'
        ]
        read_only_fields = [
            'id', 'reviewer', 'reviewer_name', 'order',
            'is_verified', 'created_at'
        ]

    def get_formatted_date(self, obj):
        """
        Get formatted review date.
        """
        return format_date(obj.created_at, '%B %d, %Y')

    def validate_overall_rating(self, value):
        """
        Validate overall rating.
        """
        if not 1 <= value <= 5:
            raise serializers.ValidationError("Overall rating must be between 1 and 5")
        return value

    def validate(self, attrs):
        """
        Validate review constraints.
        """
        order = self.context['order']
        reviewer = self.context['request'].user

        # Check if user can review this order
        if order.buyer != reviewer:
            raise serializers.ValidationError("Only buyers can review orders")

        # Check if order is delivered
        if order.status != Order.Status.DELIVERED:
            raise serializers.ValidationError("You can only review delivered orders")

        # Check if user has already reviewed this order
        if OrderReview.objects.filter(order=order, reviewer=reviewer).exists():
            raise serializers.ValidationError("You have already reviewed this order")

        # Validate individual ratings
        ratings = [
            'quality_rating', 'delivery_speed', 'communication', 'packaging'
        ]
        for rating_field in ratings:
            if rating_field in attrs and not 1 <= attrs[rating_field] <= 5:
                raise serializers.ValidationError(f"{rating_field} must be between 1 and 5")

        return attrs

    def create(self, validated_data):
        """
        Create order review.
        """
        order = self.context['order']
        reviewer = self.context['request'].user

        review = OrderReview.objects.create(
            order=order,
            reviewer=reviewer,
            **validated_data
        )

        # Create activity log
        from apps.dashboard.models import UserActivity
        UserActivity.objects.create(
            user=reviewer,
            activity_type='REVIEW',
            description=f"Reviewed order {order.order_number}",
            metadata={
                'order_id': str(order.id),
                'rating': review.overall_rating,
            }
        )

        # Send notification to seller
        from apps.notifications.models import Notification
        Notification.objects.create(
            recipient=order.seller,
            sender=reviewer,
            title=f"New review for order {order.order_number}",
            message=f"{reviewer.full_name} left a {review.overall_rating}-star review.",
            notification_type=Notification.Type.REVIEW,
            related_object_type=Notification.RelatedObjectType.ORDER,
            related_object_id=order.id,
            action_url=f"/orders/{order.id}/",
        )

        return review


class OrderSearchSerializer(serializers.Serializer):
    """
    Serializer for order search parameters.
    """
    status = serializers.ChoiceField(choices=Order.Status.choices, required=False)
    payment_status = serializers.ChoiceField(choices=Order.PaymentStatus.choices, required=False)
    payment_method = serializers.ChoiceField(choices=Order.PaymentMethod.choices, required=False)
    start_date = serializers.DateField(required=False)
    end_date = serializers.DateField(required=False)
    min_amount = serializers.DecimalField(min_value=0, required=False)
    max_amount = serializers.DecimalField(min_value=0, required=False)
    sort_by = serializers.ChoiceField(
        choices=[
            ('newest', 'Newest First'),
            ('oldest', 'Oldest First'),
            ('amount_high', 'Highest Amount First'),
            ('amount_low', 'Lowest Amount First'),
            ('status', 'Status'),
        ],
        default='newest'
    )

    def validate(self, attrs):
        """
        Validate search parameters.
        """
        start_date = attrs.get('start_date')
        end_date = attrs.get('end_date')

        if start_date and end_date and start_date > end_date:
            raise serializers.ValidationError("Start date cannot be after end date")

        min_amount = attrs.get('min_amount')
        max_amount = attrs.get('max_amount')

        if min_amount and max_amount and min_amount > max_amount:
            raise serializers.ValidationError("Minimum amount cannot be greater than maximum amount")

        return attrs