"""
Authentication utilities for AgriLink API.
"""
import secrets
import string
from datetime import datetime, timedelta
from django.utils import timezone
from django.core.cache import cache
from django.conf import settings
from django.contrib.auth import get_user_model
import hashlib

User = get_user_model()


def generate_otp(length=6):
    """
    Generate a One-Time Password (OTP).
    """
    digits = string.digits
    return ''.join(secrets.choice(digits) for _ in range(length))


def generate_token(length=32):
    """
    Generate a secure random token.
    """
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))


def is_otp_valid(otp_created_at, expiry_minutes=10):
    """
    Check if OTP is still valid.
    """
    if otp_created_at is None:
        return False

    expiry_time = otp_created_at + timedelta(minutes=expiry_minutes)
    current_time = timezone.now()

    return current_time < expiry_time


def generate_email_verification_token(user):
    """
    Generate email verification token for user.
    """
    token_data = f"{user.id}:{user.email}:{timezone.now().timestamp()}"
    token = hashlib.sha256(token_data.encode()).hexdigest()

    # Store token in cache with expiry
    cache_key = f"email_verification:{user.id}"
    cache.set(cache_key, token, timeout=3600)  # 1 hour

    return token


def verify_email_token(user, token):
    """
    Verify email verification token.
    """
    cache_key = f"email_verification:{user.id}"
    stored_token = cache.get(cache_key)

    if stored_token is None or stored_token != token:
        return False

    # Mark user as verified
    user.is_verified = True
    user.save(update_fields=['is_verified'])

    # Delete token from cache
    cache.delete(cache_key)

    return True


def generate_password_reset_token(user):
    """
    Generate password reset token for user.
    """
    token_data = f"{user.id}:{user.email}:{timezone.now().timestamp()}:{secrets.token_hex(16)}"
    token = hashlib.sha256(token_data.encode()).hexdigest()

    # Store token in cache with expiry
    cache_key = f"password_reset:{user.id}"
    cache.set(cache_key, token, timeout=1800)  # 30 minutes

    return token


def verify_password_reset_token(user, token):
    """
    Verify password reset token.
    """
    cache_key = f"password_reset:{user.id}"
    stored_token = cache.get(cache_key)

    return stored_token is not None and stored_token == token


def clear_password_reset_token(user):
    """
    Clear password reset token for user.
    """
    cache_key = f"password_reset:{user.id}"
    cache.delete(cache_key)


def create_user_activity(user, activity_type, request=None, description="", metadata=None):
    """
    Create user activity log entry.
    """
    from apps.dashboard.models import UserActivity

    activity_data = {
        'user': user,
        'activity_type': activity_type,
        'description': description,
        'metadata': metadata or {},
    }

    # Add request information if available
    if request:
        activity_data.update({
            'ip_address': get_client_ip(request),
            'user_agent': request.META.get('HTTP_USER_AGENT', ''),
            'request_path': request.path,
            'request_method': request.method,
        })

    UserActivity.objects.create(**activity_data)


def get_client_ip(request):
    """
    Get client IP address from request.
    """
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0].strip()
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip


def send_verification_email(user):
    """
    Send email verification email to user.
    """
    if user.is_verified:
        return True

    token = generate_email_verification_token(user)
    verification_url = f"{settings.FRONTEND_URL}/verify-email/?token={token}"

    subject = "Verify your AgriLink email address"
    message = f"""
    Hi {user.first_name},

    Please verify your email address by clicking the link below:

    {verification_url}

    This link will expire in 1 hour.

    If you didn't create an account with AgriLink, please ignore this email.

    Thanks,
    The AgriLink Team
    """

    try:
        from django.core.mail import send_mail
        send_mail(
            subject=subject,
            message=message,
            from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@agrilink.com'),
            recipient_list=[user.email],
            fail_silently=False,
        )
        return True
    except Exception:
        return False


def send_password_reset_email(user):
    """
    Send password reset email to user.
    """
    token = generate_password_reset_token(user)
    reset_url = f"{settings.FRONTEND_URL}/reset-password/?token={token}"

    subject = "Reset your AgriLink password"
    message = f"""
    Hi {user.first_name},

    You requested a password reset for your AgriLink account.

    Click the link below to reset your password:

    {reset_url}

    This link will expire in 30 minutes.

    If you didn't request a password reset, please ignore this email.

    Thanks,
    The AgriLink Team
    """

    try:
        from django.core.mail import send_mail
        send_mail(
            subject=subject,
            message=message,
            from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@agrilink.com'),
            recipient_list=[user.email],
            fail_silently=False,
        )
        return True
    except Exception:
        return False


def check_rate_limit(identifier, max_attempts=5, window_minutes=15):
    """
    Check if identifier has exceeded rate limit.
    """
    cache_key = f"rate_limit:{identifier}"
    attempts = cache.get(cache_key, 0)

    if attempts >= max_attempts:
        return False

    # Increment attempts counter
    cache.set(cache_key, attempts + 1, timeout=window_minutes * 60)
    return True


def clear_rate_limit(identifier):
    """
    Clear rate limit for identifier.
    """
    cache_key = f"rate_limit:{identifier}"
    cache.delete(cache_key)


def create_jwt_payload(user):
    """
    Create JWT payload for user.
    """
    from datetime import datetime, timedelta

    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'role': user.role,
        'first_name': user.first_name,
        'last_name': user.last_name,
        'is_verified': user.is_verified,
        'is_active': user.is_active,
        'iat': datetime.utcnow(),
        'exp': datetime.utcnow() + timedelta(hours=1),
    }

    return payload


def sanitize_login_input(email, password):
    """
    Sanitize login inputs.
    """
    if email:
        email = email.strip().lower()

    if password:
        password = password.strip()

    return email, password


def validate_user_status(user):
    """
    Validate user status for login.
    """
    if not user.is_active:
        raise AuthenticationException("Account is disabled")

    if not user.is_verified:
        raise AuthenticationException("Please verify your email address")

    return True


class AuthenticationError(Exception):
    """
    Custom authentication error.
    """
    pass


def is_password_strong(password):
    """
    Check if password meets strength requirements.
    """
    if len(password) < 8:
        return False

    has_upper = any(c.isupper() for c in password)
    has_lower = any(c.islower() for c in password)
    has_digit = any(c.isdigit() for c in password)
    has_special = any(c in string.punctuation for c in password)

    return has_upper and has_lower and has_digit and has_special


def get_or_create_notification_preferences(user):
    """
    Get or create notification preferences for user.
    """
    from apps.notifications.models import NotificationPreference

    preferences, created = NotificationPreference.objects.get_or_create(
        user=user,
        defaults={
            'digest_frequency': 'IMMEDIATE',
            'quiet_hours_enabled': True,
            'quiet_hours_start': '22:00',
            'quiet_hours_end': '08:00',
        }
    )

    return preferences