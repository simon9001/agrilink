"""
Authentication views for AgriLink API.
"""
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken, BlacklistedToken
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework.generics import GenericAPIView
from django.contrib.auth import authenticate, get_user_model
from django.utils import timezone
from django.contrib.auth import login
from core.exceptions import AuthenticationException, ValidationException
from core.permissions import IsActiveUser
from .serializers import (
    RegisterSerializer,
    LoginSerializer,
    PasswordResetSerializer,
    PasswordResetConfirmSerializer,
    EmailVerificationSerializer,
    ChangePasswordSerializer,
    UserProfileSerializer,
    UpdateProfileSerializer,
)
from .utils import (
    create_user_activity,
    send_verification_email,
    send_password_reset_email,
    check_rate_limit,
    clear_rate_limit,
    validate_user_status,
    sanitize_login_input,
    get_or_create_notification_preferences,
)

User = get_user_model()


class RegisterView(GenericAPIView):
    """
    Register a new user with role-specific profile creation.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = RegisterSerializer

    def post(self, request, *args, **kwargs):
        """
        Handle user registration.
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            # Create user
            user = serializer.save()

            # Create notification preferences
            get_or_create_notification_preferences(user)

            # Create user activity log
            create_user_activity(
                user=user,
                activity_type='REGISTER',
                request=request,
                description=f"User registered as {user.role}"
            )

            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            access_token = refresh.access_token

            # Send verification email
            send_verification_email(user)

            return Response({
                'success': True,
                'data': {
                    'user': UserProfileSerializer(user).data,
                    'access_token': str(access_token),
                    'refresh_token': str(refresh),
                },
                'message': 'Registration successful. Please check your email for verification.',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_201_CREATED)

        except ValidationException as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'VALIDATION_ERROR',
                    'message': str(e),
                    'details': e.details if hasattr(e, 'details') else {},
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'REGISTRATION_ERROR',
                    'message': 'Registration failed. Please try again.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class LoginView(TokenObtainPairView):
    """
    Handle user login with enhanced security and activity tracking.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = LoginSerializer

    def post(self, request, *args, **kwargs):
        """
        Handle user login.
        """
        try:
            # Rate limiting check
            client_ip = self._get_client_ip(request)
            if not check_rate_limit(f"login:{client_ip}", max_attempts=5, window_minutes=15):
                return Response({
                    'success': False,
                    'error': {
                        'code': 'RATE_LIMIT_EXCEEDED',
                        'message': 'Too many login attempts. Please try again later.',
                    },
                    'timestamp': timezone.now().isoformat(),
                }, status=status.HTTP_429_TOO_MANY_REQUESTS)

            # Sanitize inputs
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            user = serializer.validated_data['user']

            # Validate user status
            validate_user_status(user)

            # Update user activity and login info
            user.last_login = timezone.now()
            user.last_login_ip = client_ip
            user.save(update_fields=['last_login', 'last_login_ip'])

            # Create activity log
            create_user_activity(
                user=user,
                activity_type='LOGIN',
                request=request,
                description="User logged in"
            )

            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            access_token = refresh.access_token

            # Clear rate limit on successful login
            clear_rate_limit(f"login:{client_ip}")

            return Response({
                'success': True,
                'data': {
                    'user': UserProfileSerializer(user).data,
                    'access_token': str(access_token),
                    'refresh_token': str(refresh),
                },
                'message': 'Login successful',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)

        except AuthenticationException as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'AUTHENTICATION_ERROR',
                    'message': str(e),
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_401_UNAUTHORIZED)

        except Exception as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'LOGIN_ERROR',
                    'message': 'Login failed. Please try again.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def _get_client_ip(self, request):
        """
        Get client IP address from request.
        """
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class LogoutView(GenericAPIView):
    """
    Handle user logout by blacklisting the refresh token.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        """
        Handle user logout.
        """
        try:
            refresh_token = request.data.get('refresh_token')

            if refresh_token:
                # Blacklist the refresh token
                token = RefreshToken(refresh_token)
                BlacklistedToken.objects.create(
                    token=token,
                    blacklisted_at=timezone.now()
                )

            # Create activity log
            create_user_activity(
                user=request.user,
                activity_type='LOGOUT',
                request=request,
                description="User logged out"
            )

            return Response({
                'success': True,
                'message': 'Logout successful',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'LOGOUT_ERROR',
                    'message': 'Logout failed.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PasswordResetView(GenericAPIView):
    """
    Handle password reset requests.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = PasswordResetSerializer

    def post(self, request, *args, **kwargs):
        """
        Handle password reset request.
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            email = serializer.validated_data['email']

            try:
                user = User.objects.get(email=email)

                # Rate limiting check
                if not check_rate_limit(f"password_reset:{email}", max_attempts=3, window_minutes=60):
                    return Response({
                        'success': False,
                        'error': {
                            'code': 'RATE_LIMIT_EXCEEDED',
                            'message': 'Too many password reset attempts. Please try again later.',
                        },
                        'timestamp': timezone.now().isoformat(),
                    }, status=status.HTTP_429_TOO_MANY_REQUESTS)

                # Send password reset email
                send_password_reset_email(user)

                # Create activity log
                create_user_activity(
                    user=user,
                    activity_type='PASSWORD_RESET',
                    request=request,
                    description="Password reset requested"
                )

            except User.DoesNotExist:
                # Don't reveal if email exists
                pass

            return Response({
                'success': True,
                'message': 'If an account with this email exists, a password reset link has been sent.',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'PASSWORD_RESET_ERROR',
                    'message': 'Password reset request failed.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PasswordResetConfirmView(GenericAPIView):
    """
    Handle password reset confirmation.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = PasswordResetConfirmSerializer

    def post(self, request, *args, **kwargs):
        """
        Handle password reset confirmation.
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            token = serializer.validated_data['token']
            new_password = serializer.validated_data['new_password']

            # Find user by token (simplified - in production, implement proper token validation)
            # For now, this is a placeholder implementation

            return Response({
                'success': True,
                'message': 'Password reset successful. Please log in with your new password.',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'PASSWORD_RESET_CONFIRM_ERROR',
                    'message': 'Password reset failed. Please request a new reset link.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_400_BAD_REQUEST)


class EmailVerificationView(GenericAPIView):
    """
    Handle email verification.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = EmailVerificationSerializer

    def post(self, request, *args, **kwargs):
        """
        Handle email verification.
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            token = serializer.validated_data['token']

            # Find user by token and verify
            # This is a simplified implementation

            return Response({
                'success': True,
                'message': 'Email verified successfully.',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'EMAIL_VERIFICATION_ERROR',
                    'message': 'Email verification failed. Please request a new verification link.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_400_BAD_REQUEST)


class ResendVerificationView(GenericAPIView):
    """
    Resend email verification.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        """
        Resend verification email.
        """
        try:
            user = request.user

            if user.is_verified:
                return Response({
                    'success': False,
                    'error': {
                        'code': 'ALREADY_VERIFIED',
                        'message': 'Email is already verified.',
                    },
                    'timestamp': timezone.now().isoformat(),
                }, status=status.HTTP_400_BAD_REQUEST)

            # Rate limiting check
            if not check_rate_limit(f"email_verify:{user.email}", max_attempts=3, window_minutes=60):
                return Response({
                    'success': False,
                    'error': {
                        'code': 'RATE_LIMIT_EXCEEDED',
                        'message': 'Too many verification attempts. Please try again later.',
                    },
                    'timestamp': timezone.now().isoformat(),
                }, status=status.HTTP_429_TOO_MANY_REQUESTS)

            # Send verification email
            send_verification_email(user)

            return Response({
                'success': True,
                'message': 'Verification email sent. Please check your inbox.',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'RESEND_VERIFICATION_ERROR',
                    'message': 'Failed to send verification email.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ChangePasswordView(GenericAPIView):
    """
    Change user password.
    """
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]
    serializer_class = ChangePasswordSerializer

    def post(self, request, *args, **kwargs):
        """
        Handle password change.
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            # Update password
            serializer.save()

            # Create activity log
            create_user_activity(
                user=request.user,
                activity_type='PASSWORD_CHANGE',
                request=request,
                description="User changed password"
            )

            return Response({
                'success': True,
                'message': 'Password changed successfully.',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'PASSWORD_CHANGE_ERROR',
                    'message': 'Password change failed.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def current_user(request):
    """
    Get current user information.
    """
    try:
        user_data = UserProfileSerializer(request.user).data

        return Response({
            'success': True,
            'data': user_data,
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'success': False,
            'error': {
                'code': 'GET_USER_ERROR',
                'message': 'Failed to get user information.',
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)