"""
Authentication serializers for AgriLink API.
"""
from rest_framework import serializers
from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from .utils import generate_otp, is_otp_valid
from core.exceptions import ValidationException, AuthenticationException
from core.utils import is_valid_email, is_valid_phone_number

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    """
    Serializer for user registration with role-specific profile creation.
    """
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)

    # Role-specific profile data
    profile_data = serializers.JSONField(write_only=True, required=False)

    class Meta:
        model = User
        fields = [
            'email', 'password', 'password_confirm', 'first_name', 'last_name',
            'phone', 'role', 'profile_data'
        ]

    def validate_email(self, value):
        """
        Validate email format and uniqueness.
        """
        if not is_valid_email(value):
            raise serializers.ValidationError("Invalid email format")

        if User.objects.filter(email=value.lower()).exists():
            raise serializers.ValidationError("A user with this email already exists")

        return value.lower()

    def validate_phone(self, value):
        """
        Validate phone number format.
        """
        if value and not is_valid_phone_number(value):
            raise serializers.ValidationError("Invalid phone number format")
        return value

    def validate_role(self, value):
        """
        Validate user role.
        """
        valid_roles = [choice[0] for choice in User.Role.choices]
        if value not in valid_roles:
            raise serializers.ValidationError(f"Invalid role. Must be one of: {valid_roles}")
        return value

    def validate(self, attrs):
        """
        Validate cross-field dependencies.
        """
        # Check password confirmation
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError("Passwords don't match")

        # Validate role-specific profile data
        role = attrs['role']
        profile_data = attrs.get('profile_data', {})

        if role == User.Role.FARMER:
            self._validate_farmer_profile(profile_data)
        elif role == User.Role.BUYER:
            self._validate_buyer_profile(profile_data)
        elif role == User.Role.SUPPLIER:
            self._validate_supplier_profile(profile_data)
        elif role == User.Role.EXPERT:
            self._validate_expert_profile(profile_data)

        return attrs

    def _validate_farmer_profile(self, profile_data):
        """
        Validate farmer-specific profile data.
        """
        required_fields = ['farm_name', 'farm_size', 'primary_crops']
        for field in required_fields:
            if field not in profile_data:
                raise serializers.ValidationError(f"Farm profile requires {field}")

        if not isinstance(profile_data['farm_size'], (int, float)) or profile_data['farm_size'] <= 0:
            raise serializers.ValidationError("Farm size must be a positive number")

        if not isinstance(profile_data['primary_crops'], list) or len(profile_data['primary_crops']) == 0:
            raise serializers.ValidationError("Primary crops must be a non-empty list")

    def _validate_buyer_profile(self, profile_data):
        """
        Validate buyer-specific profile data.
        """
        required_fields = ['business_name', 'business_type']
        for field in required_fields:
            if field not in profile_data:
                raise serializers.ValidationError(f"Buyer profile requires {field}")

        valid_business_types = [choice[0] for choice in BuyerProfile.BusinessType.choices]
        if profile_data['business_type'] not in valid_business_types:
            raise serializers.ValidationError(f"Invalid business type. Must be one of: {valid_business_types}")

    def _validate_supplier_profile(self, profile_data):
        """
        Validate supplier-specific profile data.
        """
        required_fields = ['company_name', 'product_categories', 'business_license']
        for field in required_fields:
            if field not in profile_data:
                raise serializers.ValidationError(f"Supplier profile requires {field}")

        if not isinstance(profile_data['product_categories'], list) or len(profile_data['product_categories']) == 0:
            raise serializers.ValidationError("Product categories must be a non-empty list")

    def _validate_expert_profile(self, profile_data):
        """
        Validate expert-specific profile data.
        """
        required_fields = ['specialization', 'credentials', 'years_experience']
        for field in required_fields:
            if field not in profile_data:
                raise serializers.ValidationError(f"Expert profile requires {field}")

        if not isinstance(profile_data['years_experience'], int) or profile_data['years_experience'] < 0:
            raise serializers.ValidationError("Years of experience must be a non-negative integer")

    def create(self, validated_data):
        """
        Create user and role-specific profile.
        """
        profile_data = validated_data.pop('profile_data', {})
        password_confirm = validated_data.pop('password_confirm')

        # Create user
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            phone=validated_data.get('phone'),
            role=validated_data['role']
        )

        # Create role-specific profile
        self._create_role_profile(user, validated_data['role'], profile_data)

        return user

    def _create_role_profile(self, user, role, profile_data):
        """
        Create role-specific profile based on user role.
        """
        if role == User.Role.FARMER:
            from apps.users.models import FarmerProfile
            FarmerProfile.objects.create(user=user, **profile_data)
        elif role == User.Role.BUYER:
            from apps.users.models import BuyerProfile
            BuyerProfile.objects.create(user=user, **profile_data)
        elif role == User.Role.SUPPLIER:
            from apps.users.models import SupplierProfile
            SupplierProfile.objects.create(user=user, **profile_data)
        elif role == User.Role.EXPERT:
            from apps.users.models import ExpertProfile
            ExpertProfile.objects.create(user=user, **profile_data)


class LoginSerializer(serializers.Serializer):
    """
    Serializer for user login.
    """
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        """
        Validate credentials and authenticate user.
        """
        email = attrs.get('email').lower()
        password = attrs.get('password')

        # Authenticate user
        user = authenticate(username=email, password=password)

        if not user:
            raise AuthenticationException("Invalid email or password")

        if not user.is_active:
            raise AuthenticationException("Account is disabled")

        attrs['user'] = user
        return attrs


class PasswordResetSerializer(serializers.Serializer):
    """
    Serializer for password reset requests.
    """
    email = serializers.EmailField()

    def validate_email(self, value):
        """
        Check if email exists in the system.
        """
        if not User.objects.filter(email=value.lower()).exists():
            # Don't reveal if email exists or not for security
            pass
        return value.lower()

    def save(self):
        """
        Generate and send password reset token.
        """
        email = self.validated_data['email']

        try:
            user = User.objects.get(email=email)
            # Generate reset token and send email
            # This is a simplified version - in production, use Django's built-in password reset
            reset_token = generate_otp(length=32)

            # TODO: Store reset token with expiry and send email
            # For now, just return success
            return user
        except User.DoesNotExist:
            # Don't reveal if email exists
            return None


class PasswordResetConfirmSerializer(serializers.Serializer):
    """
    Serializer for confirming password reset.
    """
    token = serializers.CharField()
    new_password = serializers.CharField(validators=[validate_password])
    confirm_password = serializers.CharField()

    def validate(self, attrs):
        """
        Validate token and password confirmation.
        """
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError("Passwords don't match")

        # TODO: Validate reset token
        # For now, just pass validation

        return attrs


class EmailVerificationSerializer(serializers.Serializer):
    """
    Serializer for email verification.
    """
    token = serializers.CharField()

    def validate_token(self, value):
        """
        Validate verification token.
        """
        # TODO: Implement token validation logic
        return value


class ChangePasswordSerializer(serializers.Serializer):
    """
    Serializer for changing user password.
    """
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(validators=[validate_password])
    confirm_password = serializers.CharField()

    def validate_old_password(self, value):
        """
        Validate old password.
        """
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("Old password is incorrect")
        return value

    def validate(self, attrs):
        """
        Validate password confirmation.
        """
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError("Passwords don't match")
        return attrs

    def save(self):
        """
        Update user password.
        """
        user = self.context['request'].user
        user.set_password(self.validated_data['new_password'])
        user.save()
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    """
    Serializer for user profile data.
    """
    full_name = serializers.ReadOnlyField()
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    profile_completed = serializers.SerializerMethodField()
    location_coordinates = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'full_name',
            'phone', 'role', 'role_display', 'is_verified',
            'profile_picture', 'location', 'location_address',
            'location_coordinates', 'profile_completed',
            'created_at', 'last_login'
        ]
        read_only_fields = ['id', 'email', 'role', 'is_verified', 'created_at']

    def get_profile_completed(self, obj):
        """
        Check if user has completed their role-specific profile.
        """
        return obj.has_profile()

    def get_location_coordinates(self, obj):
        """
        Get location coordinates for display.
        """
        return obj.get_location_coordinates()


class UpdateProfileSerializer(serializers.ModelSerializer):
    """
    Serializer for updating user profile.
    """
    profile_data = serializers.JSONField(write_only=True, required=False)

    class Meta:
        model = User
        fields = [
            'first_name', 'last_name', 'phone', 'profile_picture',
            'location_address', 'profile_data'
        ]

    def update(self, instance, validated_data):
        """
        Update user profile and role-specific profile.
        """
        profile_data = validated_data.pop('profile_data', None)

        # Update user fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        # Update role-specific profile if provided
        if profile_data and instance.role:
            self._update_role_profile(instance, profile_data)

        return instance

    def _update_role_profile(self, user, profile_data):
        """
        Update user's role-specific profile.
        """
        if user.role == User.Role.FARMER and hasattr(user, 'farmer_profile'):
            for attr, value in profile_data.items():
                if hasattr(user.farmer_profile, attr):
                    setattr(user.farmer_profile, attr, value)
            user.farmer_profile.save()
        elif user.role == User.Role.BUYER and hasattr(user, 'buyer_profile'):
            for attr, value in profile_data.items():
                if hasattr(user.buyer_profile, attr):
                    setattr(user.buyer_profile, attr, value)
            user.buyer_profile.save()
        elif user.role == User.Role.SUPPLIER and hasattr(user, 'supplier_profile'):
            for attr, value in profile_data.items():
                if hasattr(user.supplier_profile, attr):
                    setattr(user.supplier_profile, attr, value)
            user.supplier_profile.save()
        elif user.role == User.Role.EXPERT and hasattr(user, 'expert_profile'):
            for attr, value in profile_data.items():
                if hasattr(user.expert_profile, attr):
                    setattr(user.expert_profile, attr, value)
            user.expert_profile.save()


# Import BuyerProfile for validation
try:
    from apps.users.models import BuyerProfile
except ImportError:
    # This handles the circular import issue during development
    BuyerProfile = None