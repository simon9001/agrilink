"""
Marketplace serializers for AgriLink API.
"""
from rest_framework import serializers
from django.db import models
from django.contrib.auth import get_user_model
from django.contrib.gis.geos import Point
from django.utils import timezone
from core.utils import create_point_from_coordinates, format_currency, format_date
from core.exceptions import ValidationException
from .models import ProduceCategory, ProduceListing, ListingInquiry, ListingReview

User = get_user_model()


class ProduceCategorySerializer(serializers.ModelSerializer):
    """
    Serializer for produce categories.
    """
    class Meta:
        model = ProduceCategory
        fields = ['id', 'name', 'description', 'icon', 'is_active']
        read_only_fields = ['id']


class ProduceListingSerializer(serializers.ModelSerializer):
    """
    Serializer for produce listings (create and update).
    """
    farmer = serializers.HiddenField(default=serializers.CurrentUserDefault())
    farmer_name = serializers.CharField(source='farmer.full_name', read_only=True)
    farmer_profile = serializers.SerializerMethodField()
    location_coordinates = serializers.SerializerMethodField()
    formatted_price = serializers.SerializerMethodField()
    formatted_quantity = serializers.SerializerMethodField()
    total_value = serializers.ReadOnlyField()
    is_available = serializers.ReadOnlyField()
    days_until_expiry = serializers.SerializerMethodField()
    availability_status = serializers.SerializerMethodField()

    class Meta:
        model = ProduceListing
        fields = [
            'id', 'farmer', 'farmer_name', 'farmer_profile',
            'product_name', 'category', 'variety',
            'quantity_available', 'formatted_quantity',
            'unit_price', 'formatted_price', 'total_value',
            'minimum_order', 'quality_grade', 'is_organic',
            'certification_details', 'harvest_date',
            'availability_period_start', 'availability_period_end',
            'location', 'location_coordinates', 'location_address',
            'description', 'images', 'video_url',
            'status', 'is_featured', 'view_count', 'contact_count',
            'is_available', 'days_until_expiry', 'availability_status',
            'created_at', 'updated_at', 'expires_at'
        ]
        read_only_fields = [
            'id', 'farmer', 'farmer_name', 'view_count', 'contact_count',
            'is_available', 'days_until_expiry', 'availability_status',
            'created_at', 'updated_at', 'expires_at'
        ]

    def get_farmer_profile(self, obj):
        """
        Get farmer profile information.
        """
        if hasattr(obj.farmer, 'farmer_profile'):
            profile = obj.farmer.farmer_profile
            return {
                'farm_name': profile.farm_name,
                'years_experience': profile.years_experience,
                'farm_size': profile.farm_size,
                'primary_crops': profile.primary_crops,
            }
        return None

    def get_location_coordinates(self, obj):
        """
        Get location coordinates for display.
        """
        return obj.get_location_coordinates()

    def get_formatted_price(self, obj):
        """
        Format unit price as currency.
        """
        return format_currency(obj.unit_price)

    def get_formatted_quantity(self, obj):
        """
        Format quantity with units.
        """
        return f"{obj.quantity_available:,} kg"

    def get_days_until_expiry(self, obj):
        """
        Calculate days until listing expires.
        """
        if obj.expires_at:
            days = (obj.expires_at - timezone.now()).days
            return max(0, days)
        return None

    def get_availability_status(self, obj):
        """
        Get human-readable availability status.
        """
        if obj.status == obj.Status.DRAFT:
            return "Draft"
        elif obj.status == obj.Status.ACTIVE:
            if obj.is_available:
                return "Available"
            else:
                return "Out of Season"
        elif obj.status == obj.Status.SOLD:
            return "Sold Out"
        elif obj.status == obj.Status.EXPIRED:
            return "Expired"
        elif obj.status == obj.Status.RESERVED:
            return "Reserved"
        return obj.status

    def validate_quantity_available(self, value):
        """
        Validate available quantity.
        """
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than 0")
        if value > 1000000:  # 1,000 tons
            raise serializers.ValidationError("Quantity seems unusually large")
        return value

    def validate_unit_price(self, value):
        """
        Validate unit price.
        """
        if value <= 0:
            raise serializers.ValidationError("Price must be greater than 0")
        if value > 10000:  # Very high price per kg
            raise serializers.ValidationError("Price seems unusually high")
        return value

    def validate_minimum_order(self, value):
        """
        Validate minimum order quantity.
        """
        if value <= 0:
            raise serializers.ValidationError("Minimum order must be greater than 0")
        return value

    def validate_harvest_date(self, value):
        """
        Validate harvest date.
        """
        if value > timezone.now().date():
            raise serializers.ValidationError("Harvest date cannot be in the future")
        return value

    def validate_availability_period_start(self, value):
        """
        Validate availability start date.
        """
        if value < timezone.now().date():
            raise serializers.ValidationError("Availability start date cannot be in the past")
        return value

    def validate_availability_period_end(self, value):
        """
        Validate availability end date.
        """
        start_date = self.initial_data.get('availability_period_start')
        if start_date and value <= start_date:
            raise serializers.ValidationError("Availability end date must be after start date")
        return value

    def validate_images(self, value):
        """
        Validate images list.
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Images must be a list")
        if len(value) > 10:
            raise serializers.ValidationError("Maximum 10 images allowed")
        return value

    def validate(self, attrs):
        """
        Cross-field validation.
        """
        # Validate minimum order against available quantity
        min_order = attrs.get('minimum_order', 1)
        quantity = attrs.get('quantity_available', 0)

        if min_order > quantity:
            raise serializers.ValidationError("Minimum order cannot exceed available quantity")

        # Validate availability period
        start_date = attrs.get('availability_period_start')
        end_date = attrs.get('availability_period_end')
        harvest_date = attrs.get('harvest_date')

        if harvest_date and start_date and start_date < harvest_date:
            raise serializers.ValidationError("Availability start date cannot be before harvest date")

        return attrs

    def create(self, validated_data):
        """
        Create produce listing with location handling.
        """
        # Extract latitude/longitude if provided
        latitude = validated_data.pop('latitude', None)
        longitude = validated_data.pop('longitude', None)

        listing = ProduceListing.objects.create(**validated_data)

        # Set location if coordinates provided
        if latitude is not None and longitude is not None:
            listing.set_location(latitude, longitude)

        return listing

    def update(self, instance, validated_data):
        """
        Update produce listing with location handling.
        """
        # Extract latitude/longitude if provided
        latitude = validated_data.pop('latitude', None)
        longitude = validated_data.pop('longitude', None)

        # Update fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        # Update location if coordinates provided
        if latitude is not None and longitude is not None:
            instance.set_location(latitude, longitude)

        instance.save()
        return instance


class ProduceListingDetailSerializer(ProduceListingSerializer):
    """
    Detailed serializer for produce listings with additional information.
    """
    farmer_location = serializers.SerializerMethodField()
    farmer_rating = serializers.SerializerMethodField()
    reviews_summary = serializers.SerializerMethodField()
    related_listings = serializers.SerializerMethodField()

    class Meta(ProduceListingSerializer.Meta):
        fields = ProduceListingSerializer.Meta.fields + [
            'farmer_location', 'farmer_rating', 'reviews_summary',
            'related_listings'
        ]

    def get_farmer_location(self, obj):
        """
        Get farmer's location (approximate for privacy).
        """
        coords = obj.farmer.get_location_coordinates()
        if coords:
            # Round coordinates for privacy
            return {
                'latitude': round(coords['latitude'], 2),
                'longitude': round(coords['longitude'], 2)
            }
        return None

    def get_farmer_rating(self, obj):
        """
        Get farmer's average rating.
        """
        from apps.orders.models import OrderReview
        reviews = OrderReview.objects.filter(order__seller=obj.farmer)
        if reviews.exists():
            avg_rating = reviews.aggregate(avg_rating=models.Avg('overall_rating'))['avg_rating']
            return {
                'average_rating': round(avg_rating, 2),
                'total_reviews': reviews.count(),
            }
        return None

    def get_reviews_summary(self, obj):
        """
        Get reviews summary for this listing.
        """
        reviews = obj.reviews.all()
        if reviews.exists():
            avg_rating = reviews.aggregate(avg_rating=models.Avg('rating'))['avg_rating']
            return {
                'average_rating': round(avg_rating, 2),
                'total_reviews': reviews.count(),
                'recent_reviews': ListingReviewSerializer(
                    reviews.order_by('-created_at')[:3], many=True
                ).data,
            }
        return None

    def get_related_listings(self, obj):
        """
        Get related listings from same farmer.
        """
        related = ProduceListing.objects.filter(
            farmer=obj.farmer,
            status=ProduceListing.Status.ACTIVE
        ).exclude(id=obj.id)[:3]

        return ProduceListingSerializer(related, many=True).data


class ListingInquirySerializer(serializers.ModelSerializer):
    """
    Serializer for listing inquiries.
    """
    buyer_name = serializers.CharField(source='buyer.full_name', read_only=True)
    listing_title = serializers.CharField(source='listing.product_name', read_only=True)
    formatted_quantity = serializers.SerializerMethodField()
    formatted_price = serializers.SerializerMethodField()

    class Meta:
        model = ListingInquiry
        fields = [
            'id', 'listing', 'buyer', 'buyer_name', 'listing_title',
            'message', 'quantity_requested', 'formatted_quantity',
            'proposed_price', 'formatted_price',
            'response_message', 'response_price',
            'status', 'created_at', 'responded_at'
        ]
        read_only_fields = ['id', 'buyer', 'buyer_name', 'listing_title', 'created_at', 'responded_at']

    def get_formatted_quantity(self, obj):
        """
        Format requested quantity.
        """
        return f"{obj.quantity_requested:,} kg"

    def get_formatted_price(self, obj):
        """
        Format proposed price.
        """
        if obj.proposed_price:
            return format_currency(obj.proposed_price)
        return None

    def validate_quantity_requested(self, value):
        """
        Validate requested quantity.
        """
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than 0")
        return value

    def validate_proposed_price(self, value):
        """
        Validate proposed price.
        """
        if value is not None and value <= 0:
            raise serializers.ValidationError("Proposed price must be greater than 0")
        return value

    def validate(self, attrs):
        """
        Validate inquiry against listing availability.
        """
        listing = self.context.get('listing')
        if not listing:
            raise serializers.ValidationError("Listing is required")

        # Check if buyer is the listing owner
        buyer = self.context['request'].user
        if listing.farmer == buyer:
            raise serializers.ValidationError("Cannot inquire about your own listing")

        # Check if listing is available
        if not listing.is_available:
            raise serializers.ValidationError("This listing is not available for inquiry")

        # Validate quantity against listing availability
        quantity = attrs.get('quantity_requested', 0)
        if quantity > listing.quantity_available:
            raise serializers.ValidationError(
                f"Requested quantity exceeds available amount ({listing.quantity_available} kg)"
            )

        return attrs

    def create(self, validated_data):
        """
        Create listing inquiry.
        """
        listing = self.context.get('listing')
        buyer = self.context['request'].user

        inquiry = ListingInquiry.objects.create(
            listing=listing,
            buyer=buyer,
            **validated_data
        )

        # Create activity log
        from apps.dashboard.models import UserActivity
        UserActivity.objects.create(
            user=buyer,
            activity_type='INQUIRY_SEND',
            description=f"Inquiry sent for {listing.product_name}",
            metadata={'listing_id': str(listing.id), 'inquiry_id': str(inquiry.id)}
        )

        return inquiry


class ListingReviewSerializer(serializers.ModelSerializer):
    """
    Serializer for listing reviews.
    """
    reviewer_name = serializers.CharField(source='reviewer.full_name', read_only=True)
    formatted_date = serializers.SerializerMethodField()

    class Meta:
        model = ListingReview
        fields = [
            'id', 'listing', 'reviewer', 'reviewer_name',
            'rating', 'comment', 'quality_rating',
            'communication_rating', 'delivery_rating',
            'is_verified_purchase', 'is_helpful_count',
            'formatted_date', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'reviewer', 'reviewer_name', 'is_verified_purchase',
            'is_helpful_count', 'created_at', 'updated_at'
        ]

    def get_formatted_date(self, obj):
        """
        Get formatted review date.
        """
        return format_date(obj.created_at, '%B %d, %Y')

    def validate_rating(self, value):
        """
        Validate rating value.
        """
        if not 1 <= value <= 5:
            raise serializers.ValidationError("Rating must be between 1 and 5")
        return value

    def validate(self, attrs):
        """
        Validate review constraints.
        """
        listing = self.context.get('listing')
        reviewer = self.context['request'].user

        # Check if user can review this listing
        if listing.farmer == reviewer:
            raise serializers.ValidationError("Cannot review your own listing")

        # Check if user has already reviewed this listing
        if ListingReview.objects.filter(listing=listing, reviewer=reviewer).exists():
            raise serializers.ValidationError("You have already reviewed this listing")

        return attrs

    def create(self, validated_data):
        """
        Create listing review.
        """
        listing = self.context.get('listing')
        reviewer = self.context['request'].user

        review = ListingReview.objects.create(
            listing=listing,
            reviewer=reviewer,
            **validated_data
        )

        # Create activity log
        from apps.dashboard.models import UserActivity
        UserActivity.objects.create(
            user=reviewer,
            activity_type='REVIEW',
            description=f"Review posted for {listing.product_name}",
            metadata={'listing_id': str(listing.id), 'rating': review.rating}
        )

        return review


class ListingSearchSerializer(serializers.Serializer):
    """
    Serializer for listing search parameters.
    """
    category = serializers.CharField(required=False)
    location = serializers.CharField(required=False, help_text="City or region name")
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False)
    radius_km = serializers.IntegerField(min_value=1, max_value=500, default=50)
    price_min = serializers.DecimalField(min_value=0, required=False)
    price_max = serializers.DecimalField(min_value=0, required=False)
    organic_only = serializers.BooleanField(default=False)
    quality_grade = serializers.ChoiceField(
        choices=ProduceListing.QualityGrade.choices,
        required=False
    )
    farmer_rating_min = serializers.DecimalField(max_digits=2, decimal_places=1, min_value=1, max_value=5, required=False)
    sort_by = serializers.ChoiceField(
        choices=[
            ('newest', 'Newest First'),
            ('price_low', 'Price: Low to High'),
            ('price_high', 'Price: High to Low'),
            ('rating', 'Highest Rated'),
            ('distance', 'Nearest First'),
        ],
        default='newest'
    )

    def validate(self, attrs):
        """
        Validate search parameters.
        """
        latitude = attrs.get('latitude')
        longitude = attrs.get('longitude')

        # If location coordinates provided, both must be present
        if (latitude is not None) != (longitude is not None):
            raise serializers.ValidationError("Both latitude and longitude must be provided for location search")

        # Validate price range
        price_min = attrs.get('price_min')
        price_max = attrs.get('price_max')
        if price_min is not None and price_max is not None and price_min > price_max:
            raise serializers.ValidationError("Minimum price cannot be greater than maximum price")

        return attrs