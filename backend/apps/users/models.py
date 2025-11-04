"""
User models for AgriLink.
"""
import uuid
from django.contrib.auth.models import AbstractUser
from django.contrib.gis.db import models
from django.contrib.gis.geos import Point
from django.core.validators import RegexValidator
from django.utils import timezone
from core.utils import create_point_from_coordinates


class User(AbstractUser):
    """
    Custom User model with role-based access control.
    """
    class Role(models.TextChoices):
        FARMER = 'FARMER', 'Farmer'
        BUYER = 'BUYER', 'Buyer'
        SUPPLIER = 'SUPPLIER', 'Supplier'
        EXPERT = 'EXPERT', 'Expert'
        ADMIN = 'ADMIN', 'Admin'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, db_index=True)
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)

    # Phone validation
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message="Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed."
    )
    phone = models.CharField(validators=[phone_regex], max_length=20, blank=True, null=True)

    role = models.CharField(max_length=20, choices=Role.choices, db_index=True)
    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False, db_index=True)
    profile_picture = models.URLField(blank=True, null=True)

    # Location using PostGIS
    location = models.PointField(geography=True, blank=True, null=True)
    location_address = models.CharField(max_length=255, blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_login_ip = models.GenericIPAddressField(blank=True, null=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name', 'role']

    class Meta:
        db_table = 'users'
        indexes = [
            models.Index(fields=['role', 'is_active']),
            models.Index(fields=['email']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f"{self.email} ({self.role})"

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}".strip()

    def set_location(self, latitude, longitude, address=None):
        """
        Set user location from latitude and longitude.
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

    def has_profile(self):
        """
        Check if user has role-specific profile.
        """
        if self.role == self.Role.FARMER:
            return hasattr(self, 'farmer_profile')
        elif self.role == self.Role.BUYER:
            return hasattr(self, 'buyer_profile')
        elif self.role == self.Role.SUPPLIER:
            return hasattr(self, 'supplier_profile')
        elif self.role == self.Role.EXPERT:
            return hasattr(self, 'expert_profile')
        return True  # Admin doesn't need additional profile

    def get_profile(self):
        """
        Get user's role-specific profile.
        """
        if self.role == self.Role.FARMER:
            return getattr(self, 'farmer_profile', None)
        elif self.role == self.Role.BUYER:
            return getattr(self, 'buyer_profile', None)
        elif self.role == self.Role.SUPPLIER:
            return getattr(self, 'supplier_profile', None)
        elif self.role == self.Role.EXPERT:
            return getattr(self, 'expert_profile', None)
        return None


class FarmerProfile(models.Model):
    """
    Farmer-specific profile information.
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='farmer_profile')
    farm_name = models.CharField(max_length=100, db_index=True)
    farm_size = models.DecimalField(max_digits=10, decimal_places=2, help_text="Farm size in hectares")
    farm_location = models.PointField(geography=True, blank=True, null=True)
    farm_address = models.CharField(max_length=255, blank=True, null=True)

    # Crop information
    primary_crops = models.JSONField(default=list, help_text="List of primary crops")
    production_capacity = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        help_text="Annual production capacity in kg"
    )

    # Certification details
    certification = models.JSONField(
        default=dict,
        help_text="Certification details (organic, gap, etc.)"
    )
    farm_description = models.TextField(blank=True)
    years_experience = models.IntegerField(default=0)

    # Business information
    business_registration = models.CharField(max_length=100, blank=True, null=True)
    tax_id = models.CharField(max_length=50, blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'farmer_profiles'
        indexes = [
            models.Index(fields=['user', 'farm_size']),
            models.Index(fields=['primary_crops']),
        ]

    def __str__(self):
        return f"{self.user.full_name} - {self.farm_name}"

    def set_farm_location(self, latitude, longitude, address=None):
        """
        Set farm location from latitude and longitude.
        """
        if latitude is not None and longitude is not None:
            self.farm_location = create_point_from_coordinates(latitude, longitude)
            self.farm_address = address
            self.save()

    def get_farm_location_coordinates(self):
        """
        Get latitude and longitude from farm location Point.
        """
        if self.farm_location:
            return {
                'latitude': self.farm_location.y,
                'longitude': self.farm_location.x
            }
        return None


class BuyerProfile(models.Model):
    """
    Buyer-specific profile information.
    """
    class BusinessType(models.TextChoices):
        RESTAURANT = 'RESTAURANT', 'Restaurant'
        GROCERY = 'GROCERY', 'Grocery Store'
        PROCESSOR = 'PROCESSOR', 'Food Processor'
        EXPORTER = 'EXPORTER', 'Exporter'
        WHOLESALER = 'WHOLESALER', 'Wholesaler'
        RETAIL = 'RETAIL', 'Retail'

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='buyer_profile')
    business_name = models.CharField(max_length=100, db_index=True)
    business_type = models.CharField(max_length=20, choices=BusinessType.choices)

    # Buying preferences
    buying_preferences = models.JSONField(
        default=dict,
        help_text="Crop types, quality requirements, etc."
    )
    annual_volume = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        help_text="Estimated annual purchase volume in kg"
    )
    storage_capacity = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        blank=True,
        null=True,
        help_text="Storage capacity in kg"
    )

    # Geographic preferences
    delivery_regions = models.JSONField(
        default=list,
        help_text="Preferred delivery regions"
    )
    service_radius = models.IntegerField(
        default=100,
        help_text="Service radius in km"
    )

    # Payment terms
    payment_terms = models.CharField(
        max_length=20,
        choices=[
            ('CASH', 'Cash'),
            ('CREDIT', 'Credit'),
            ('CONTRACT', 'Contract'),
        ],
        default='CASH'
    )

    # Business details
    business_license = models.CharField(max_length=100, blank=True, null=True)
    tax_id = models.CharField(max_length=50, blank=True, null=True)
    website = models.URLField(blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'buyer_profiles'
        indexes = [
            models.Index(fields=['user', 'business_type']),
            models.Index(fields=['annual_volume']),
        ]

    def __str__(self):
        return f"{self.user.full_name} - {self.business_name}"


class SupplierProfile(models.Model):
    """
    Supplier-specific profile information.
    """
    class ProductCategory(models.TextChoices):
        SEEDS = 'SEEDS', 'Seeds'
        FERTILIZERS = 'FERTILIZERS', 'Fertilizers'
        TOOLS = 'TOOLS', 'Tools'
        MACHINERY = 'MACHINERY', 'Machinery'
        PESTICIDES = 'PESTICIDES', 'Pesticides'
        IRRIGATION = 'IRRIGATION', 'Irrigation'
        PACKAGING = 'PACKAGING', 'Packaging'

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='supplier_profile')
    company_name = models.CharField(max_length=100, db_index=True)

    product_categories = models.JSONField(
        default=list,
        help_text="List of product categories"
    )
    service_area = models.JSONField(
        default=dict,
        help_text="Geographic coverage area"
    )
    delivery_capacity = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        help_text="Delivery capacity in tons"
    )

    # Business information
    business_license = models.URLField(help_text="URL or file path to business license")
    specializations = models.TextField(help_text="Company specializations")

    # Verification status
    is_verified_supplier = models.BooleanField(default=False)
    verification_date = models.DateTimeField(blank=True, null=True)

    # Ratings and reviews
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.0)
    total_reviews = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'supplier_profiles'
        indexes = [
            models.Index(fields=['user', 'is_verified_supplier']),
            models.Index(fields=['average_rating']),
        ]

    def __str__(self):
        return f"{self.user.full_name} - {self.company_name}"


class ExpertProfile(models.Model):
    """
    Expert-specific profile information.
    """
    class Specialization(models.TextChoices):
        CROP_MANAGEMENT = 'CROP_MANAGEMENT', 'Crop Management'
        PEST_CONTROL = 'PEST_CONTROL', 'Pest Control'
        IRRIGATION = 'IRRIGATION', 'Irrigation'
        SOIL_HEALTH = 'SOIL_HEALTH', 'Soil Health'
        LIVESTOCK = 'LIVESTOCK', 'Livestock'
        ORGANIC_FARMING = 'ORGANIC_FARMING', 'Organic Farming'
        SUSTAINABLE_AGRICULTURE = 'SUSTAINABLE_AGRICULTURE', 'Sustainable Agriculture'

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='expert_profile')
    specialization = models.JSONField(
        default=list,
        help_text="List of specializations"
    )
    credentials = models.JSONField(
        default=dict,
        help_text="Degrees, certifications, licenses"
    )
    years_experience = models.IntegerField(default=0)

    # Consultation details
    consultation_rate = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text="Consultation rate per hour in USD"
    )
    availability = models.JSONField(
        default=dict,
        help_text="Schedule and language availability"
    )

    # Rating and verification
    rating = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=0.0,
        help_text="Expert rating 0-5"
    )
    total_consultations = models.IntegerField(default=0)
    is_verified_expert = models.BooleanField(default=False)
    verification_date = models.DateTimeField(blank=True, null=True)

    # Professional details
    bio = models.TextField(help_text="Professional biography")
    linkedin_profile = models.URLField(blank=True, null=True)
    website = models.URLField(blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'expert_profiles'
        indexes = [
            models.Index(fields=['user', 'is_verified_expert']),
            models.Index(fields=['rating']),
            models.Index(fields=['specialization']),
        ]

    def __str__(self):
        return f"{self.user.full_name} - Expert"