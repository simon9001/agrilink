"""
User profile serializers for AgriLink API.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.gis.geos import Point
from core.utils import create_point_from_coordinates, format_currency, format_date
from core.exceptions import ValidationException
from .models import FarmerProfile, BuyerProfile, SupplierProfile, ExpertProfile

User = get_user_model()


class BaseProfileSerializer(serializers.ModelSerializer):
    """
    Base serializer for role-specific profiles.
    """
    class Meta:
        abstract = True

    def validate(self, attrs):
        """
        Common profile validation.
        """
        # Add any common validation logic here
        return attrs


class FarmerProfileSerializer(BaseProfileSerializer):
    """
    Serializer for farmer profile.
    """
    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    location_coordinates = serializers.SerializerMethodField()
    farm_location_coordinates = serializers.SerializerMethodField()
    formatted_farm_size = serializers.SerializerMethodField()
    formatted_capacity = serializers.SerializerMethodField()

    class Meta:
        model = FarmerProfile
        fields = [
            'id', 'user', 'farm_name', 'farm_size', 'formatted_farm_size',
            'farm_location', 'farm_location_coordinates', 'farm_address',
            'primary_crops', 'production_capacity', 'formatted_capacity',
            'certification', 'farm_description', 'years_experience',
            'business_registration', 'tax_id',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']

    def get_location_coordinates(self, obj):
        """
        Get farm location coordinates for display.
        """
        return obj.get_farm_location_coordinates()

    def get_farm_location_coordinates(self, obj):
        """
        Get farm location coordinates for display (alias).
        """
        return obj.get_farm_location_coordinates()

    def get_formatted_farm_size(self, obj):
        """
        Format farm size with units.
        """
        return f"{obj.farm_size} hectares"

    def get_formatted_capacity(self, obj):
        """
        Format production capacity with units.
        """
        return f"{obj.production_capacity:,} kg/year"

    def validate_farm_size(self, value):
        """
        Validate farm size.
        """
        if value <= 0:
            raise serializers.ValidationError("Farm size must be greater than 0")
        if value > 10000:  # 10,000 hectares (100 km²)
            raise serializers.ValidationError("Farm size seems unusually large")
        return value

    def validate_production_capacity(self, value):
        """
        Validate production capacity.
        """
        if value <= 0:
            raise serializers.ValidationError("Production capacity must be greater than 0")
        return value

    def validate_years_experience(self, value):
        """
        Validate years of experience.
        """
        if value < 0:
            raise serializers.ValidationError("Years of experience cannot be negative")
        if value > 100:
            raise serializers.ValidationError("Years of experience seems unrealistic")
        return value

    def validate_primary_crops(self, value):
        """
        Validate primary crops list.
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Primary crops must be a list")
        if len(value) == 0:
            raise serializers.ValidationError("At least one primary crop is required")
        if len(value) > 20:
            raise serializers.ValidationError("Too many primary crops (maximum 20)")
        return value


class BuyerProfileSerializer(BaseProfileSerializer):
    """
    Serializer for buyer profile.
    """
    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    business_type_display = serializers.CharField(source='get_business_type_display', read_only=True)
    formatted_annual_volume = serializers.SerializerMethodField()
    formatted_storage_capacity = serializers.SerializerMethodField()

    class Meta:
        model = BuyerProfile
        fields = [
            'id', 'user', 'business_name', 'business_type', 'business_type_display',
            'buying_preferences', 'annual_volume', 'formatted_annual_volume',
            'storage_capacity', 'formatted_storage_capacity',
            'delivery_regions', 'service_radius', 'payment_terms',
            'business_license', 'tax_id', 'website',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']

    def get_formatted_annual_volume(self, obj):
        """
        Format annual volume with units.
        """
        return f"{obj.annual_volume:,} kg/year"

    def get_formatted_storage_capacity(self, obj):
        """
        Format storage capacity with units.
        """
        if obj.storage_capacity:
            return f"{obj.storage_capacity:,} kg"
        return "Not specified"

    def validate_annual_volume(self, value):
        """
        Validate annual volume.
        """
        if value <= 0:
            raise serializers.ValidationError("Annual volume must be greater than 0")
        return value

    def validate_service_radius(self, value):
        """
        Validate service radius.
        """
        if value <= 0:
            raise serializers.ValidationError("Service radius must be greater than 0")
        if value > 10000:  # 10,000 km (more than Earth's circumference)
            raise serializers.ValidationError("Service radius seems unrealistic")
        return value

    def validate_delivery_regions(self, value):
        """
        Validate delivery regions list.
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Delivery regions must be a list")
        return value


class SupplierProfileSerializer(BaseProfileSerializer):
    """
    Serializer for supplier profile.
    """
    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    formatted_delivery_capacity = serializers.SerializerMethodField()
    rating_display = serializers.SerializerMethodField()
    verification_status = serializers.SerializerMethodField()

    class Meta:
        model = SupplierProfile
        fields = [
            'id', 'user', 'company_name', 'product_categories',
            'service_area', 'delivery_capacity', 'formatted_delivery_capacity',
            'business_license', 'specializations',
            'is_verified_supplier', 'verification_status', 'verification_date',
            'average_rating', 'rating_display', 'total_reviews',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'user', 'is_verified_supplier', 'verification_date',
            'average_rating', 'total_reviews', 'created_at', 'updated_at'
        ]

    def get_formatted_delivery_capacity(self, obj):
        """
        Format delivery capacity with units.
        """
        return f"{obj.delivery_capacity:,} tons"

    def get_rating_display(self, obj):
        """
        Get formatted rating display.
        """
        if obj.average_rating > 0:
            return f"{obj.average_rating:.1f}/5.0 ({obj.total_reviews} reviews)"
        return "No reviews yet"

    def get_verification_status(self, obj):
        """
        Get verification status text.
        """
        return "Verified" if obj.is_verified_supplier else "Not Verified"

    def validate_delivery_capacity(self, value):
        """
        Validate delivery capacity.
        """
        if value <= 0:
            raise serializers.ValidationError("Delivery capacity must be greater than 0")
        return value

    def validate_product_categories(self, value):
        """
        Validate product categories list.
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Product categories must be a list")
        if len(value) == 0:
            raise serializers.ValidationError("At least one product category is required")
        return value


class ExpertProfileSerializer(BaseProfileSerializer):
    """
    Serializer for expert profile.
    """
    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    formatted_consultation_rate = serializers.SerializerMethodField()
    rating_display = serializers.SerializerMethodField()
    verification_status = serializers.SerializerMethodField()
    experience_level = serializers.SerializerMethodField()

    class Meta:
        model = ExpertProfile
        fields = [
            'id', 'user', 'specialization', 'credentials',
            'years_experience', 'experience_level',
            'consultation_rate', 'formatted_consultation_rate',
            'availability', 'rating', 'rating_display', 'total_consultations',
            'is_verified_expert', 'verification_status', 'verification_date',
            'bio', 'linkedin_profile', 'website',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'user', 'rating', 'total_consultations',
            'is_verified_expert', 'verification_date', 'created_at', 'updated_at'
        ]

    def get_formatted_consultation_rate(self, obj):
        """
        Format consultation rate.
        """
        return format_currency(obj.consultation_rate)

    def get_rating_display(self, obj):
        """
        Get formatted rating display.
        """
        if obj.rating > 0:
            return f"{obj.rating:.1f}/5.0 ({obj.total_consultations} consultations)"
        return "No ratings yet"

    def get_verification_status(self, obj):
        """
        Get verification status text.
        """
        return "Verified Expert" if obj.is_verified_expert else "Expert (Not Verified)"

    def get_experience_level(self, obj):
        """
        Get experience level based on years of experience.
        """
        if obj.years_experience < 2:
            return "Junior"
        elif obj.years_experience < 5:
            return "Mid-level"
        elif obj.years_experience < 10:
            return "Senior"
        else:
            return "Expert"

    def validate_consultation_rate(self, value):
        """
        Validate consultation rate.
        """
        if value <= 0:
            raise serializers.ValidationError("Consultation rate must be greater than 0")
        if value > 10000:  # Very high rate
            raise serializers.ValidationError("Consultation rate seems unusually high")
        return value

    def validate_years_experience(self, value):
        """
        Validate years of experience.
        """
        if value < 0:
            raise serializers.ValidationError("Years of experience cannot be negative")
        if value > 80:
            raise serializers.ValidationError("Years of experience seems unrealistic")
        return value

    def validate_specialization(self, value):
        """
        Validate specialization list.
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Specialization must be a list")
        if len(value) == 0:
            raise serializers.ValidationError("At least one specialization is required")
        if len(value) > 10:
            raise serializers.ValidationError("Too many specializations (maximum 10)")
        return value


class UserProfileSerializer(serializers.ModelSerializer):
    """
    Comprehensive user profile serializer including role-specific data.
    """
    full_name = serializers.ReadOnlyField()
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    location_coordinates = serializers.SerializerMethodField()
    profile_completed = serializers.BooleanField(read_only=True)
    farmer_profile = FarmerProfileSerializer(read_only=True)
    buyer_profile = BuyerProfileSerializer(read_only=True)
    supplier_profile = SupplierProfileSerializer(read_only=True)
    expert_profile = ExpertProfileSerializer(read_only=True)
    registration_date = serializers.SerializerMethodField()
    last_login_formatted = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'full_name',
            'phone', 'role', 'role_display', 'is_active', 'is_verified',
            'profile_picture', 'location', 'location_coordinates', 'location_address',
            'profile_completed', 'farmer_profile', 'buyer_profile',
            'supplier_profile', 'expert_profile',
            'registration_date', 'last_login', 'last_login_formatted',
            'last_login_ip'
        ]
        read_only_fields = [
            'id', 'email', 'role', 'is_active', 'is_verified',
            'profile_completed', 'registration_date', 'last_login', 'last_login_ip'
        ]

    def get_location_coordinates(self, obj):
        """
        Get location coordinates for display.
        """
        return obj.get_location_coordinates()

    def get_registration_date(self, obj):
        """
        Get formatted registration date.
        """
        return format_date(obj.created_at, '%B %d, %Y')

    def get_last_login_formatted(self, obj):
        """
        Get formatted last login date.
        """
        if obj.last_login:
            return format_date(obj.last_login, '%B %d, %Y at %I:%M %p')
        return "Never logged in"

    def validate_phone(self, value):
        """
        Validate phone number format.
        """
        if value:
            from core.utils import is_valid_phone_number
            if not is_valid_phone_number(value):
                raise serializers.ValidationError("Invalid phone number format")
        return value


class PublicProfileSerializer(serializers.ModelSerializer):
    """
    Public profile serializer (limited information for other users).
    """
    full_name = serializers.ReadOnlyField()
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    location_coordinates = serializers.SerializerMethodField()
    farmer_profile = serializers.SerializerMethodField()
    buyer_profile = serializers.SerializerMethodField()
    supplier_profile = serializers.SerializerMethodField()
    expert_profile = serializers.SerializerMethodField()
    member_since = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'first_name', 'last_name', 'full_name',
            'role', 'role_display', 'profile_picture',
            'location_coordinates', 'location_address',
            'farmer_profile', 'buyer_profile', 'supplier_profile', 'expert_profile',
            'member_since'
        ]
        read_only_fields = ['id', 'email', 'role']

    def get_location_coordinates(self, obj):
        """
        Get location coordinates (with privacy - approximate location only).
        """
        coords = obj.get_location_coordinates()
        if coords:
            # Round coordinates for privacy
            return {
                'latitude': round(coords['latitude'], 2),
                'longitude': round(coords['longitude'], 2)
            }
        return None

    def get_member_since(self, obj):
        """
        Get formatted member since date.
        """
        return format_date(obj.created_at, '%B %Y')

    def _get_role_profile(self, obj, role, serializer_class):
        """
        Get role-specific profile with limited fields.
        """
        if obj.role == role and hasattr(obj, f'{role.lower()}_profile'):
            profile = getattr(obj, f'{role.lower()}_profile')
            # Return limited fields for public view
            limited_data = {}
            if role == User.Role.FARMER:
                limited_data = {
                    'farm_name': profile.farm_name,
                    'primary_crops': profile.primary_crops,
                    'farm_description': profile.farm_description,
                    'years_experience': profile.years_experience,
                }
            elif role == User.Role.BUYER:
                limited_data = {
                    'business_name': profile.business_name,
                    'business_type': profile.business_type,
                    'business_type_display': profile.get_business_type_display(),
                }
            elif role == User.Role.SUPPLIER:
                limited_data = {
                    'company_name': profile.company_name,
                    'product_categories': profile.product_categories,
                    'specializations': profile.specializations,
                    'average_rating': profile.average_rating,
                    'is_verified_supplier': profile.is_verified_supplier,
                }
            elif role == User.Role.EXPERT:
                limited_data = {
                    'specialization': profile.specialization,
                    'years_experience': profile.years_experience,
                    'rating': profile.rating,
                    'is_verified_expert': profile.is_verified_expert,
                    'bio': profile.bio,
                }
            return limited_data
        return None

    def get_farmer_profile(self, obj):
        """
        Get farmer profile for public view.
        """
        return self._get_role_profile(obj, User.Role.FARMER, FarmerProfileSerializer)

    def get_buyer_profile(self, obj):
        """
        Get buyer profile for public view.
        """
        return self._get_role_profile(obj, User.Role.BUYER, BuyerProfileSerializer)

    def get_supplier_profile(self, obj):
        """
        Get supplier profile for public view.
        """
        return self._get_role_profile(obj, User.Role.SUPPLIER, SupplierProfileSerializer)

    def get_expert_profile(self, obj):
        """
        Get expert profile for public view.
        """
        return self._get_role_profile(obj, User.Role.EXPERT, ExpertProfileSerializer)


class UserListSerializer(serializers.ModelSerializer):
    """
    Simple user list serializer for admin views.
    """
    full_name = serializers.ReadOnlyField()
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    profile_completed = serializers.BooleanField(read_only=True)
    registration_date = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'role', 'role_display',
            'is_active', 'is_verified', 'profile_completed',
            'registration_date', 'last_login'
        ]

    def get_registration_date(self, obj):
        """
        Get formatted registration date.
        """
        return format_date(obj.created_at, '%Y-%m-%d')


class LocationUpdateSerializer(serializers.Serializer):
    """
    Serializer for updating user location.
    """
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    address = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        """
        Validate coordinates.
        """
        latitude = attrs['latitude']
        longitude = attrs['longitude']

        if not -90 <= latitude <= 90:
            raise serializers.ValidationError("Latitude must be between -90 and 90")

        if not -180 <= longitude <= 180:
            raise serializers.ValidationError("Longitude must be between -180 and 180")

        return attrs

    def save(self, user):
        """
        Update user location.
        """
        latitude = self.validated_data['latitude']
        longitude = self.validated_data['longitude']
        address = self.validated_data.get('address', '')

        user.set_location(latitude, longitude, address)
        return user