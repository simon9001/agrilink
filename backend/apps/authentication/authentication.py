"""
Custom JWT authentication for AgriLink API.
"""
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken
from rest_framework import status
from django.contrib.auth import get_user_model
from django.utils import timezone
from .utils import validate_user_status

User = get_user_model()


class AgriLinkJWTAuthentication(JWTAuthentication):
    """
    Custom JWT authentication with user status validation.
    """

    def get_validated_token(self, raw_token):
        """
        Validate token and check user status.
        """
        token = super().get_validated_token(raw_token)

        # Get user from token
        user_id = token.get('user_id')
        if not user_id:
            raise InvalidToken("Token contains no user identification")

        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            raise InvalidToken("Token user not found")

        # Validate user status
        validate_user_status(user)

        return token

    def get_user(self, validated_token):
        """
        Get user from validated token.
        """
        try:
            user_id = validated_token['user_id']
            user = User.objects.get(id=user_id)

            # Add user role to token for easier access
            validated_token['role'] = user.role
            validated_token['is_verified'] = user.is_verified

            return user

        except (User.DoesNotExist, KeyError):
            return None


class AgriLinkTokenObtainPairView:
    """
    Custom token obtain view with enhanced claims.
    """

    @classmethod
    def get_token(cls, user):
        """
        Generate token with custom claims.
        """
        from rest_framework_simplejwt.tokens import RefreshToken

        token = RefreshToken.for_user(user)

        # Add custom claims
        token['role'] = user.role
        token['first_name'] = user.first_name
        token['last_name'] = user.last_name
        token['is_verified'] = user.is_verified
        token['is_active'] = user.is_active
        token['profile_completed'] = user.has_profile()

        return token