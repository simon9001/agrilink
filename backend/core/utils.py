"""
Utility functions for AgriLink API.
"""
import uuid
import random
import string
from datetime import datetime, timedelta
from django.core.mail import send_mail
from django.conf import settings
from django.contrib.gis.geos import Point
from django.utils import timezone
import logging

logger = logging.getLogger(__name__)


def generate_order_number():
    """
    Generate a unique order number.
    """
    timestamp = datetime.now().strftime('%Y%m%d')
    random_str = ''.join(random.choices(string.digits, k=6))
    return f'ORD-{timestamp}-{random_str}'


def generate_unique_id():
    """
    Generate a unique UUID4.
    """
    return uuid.uuid4()


def create_point_from_coordinates(latitude, longitude):
    """
    Create a Point object from latitude and longitude.
    """
    if latitude is None or longitude is None:
        return None
    return Point(longitude, latitude, srid=4326)


def calculate_distance(point1, point2):
    """
    Calculate distance between two points in kilometers.
    """
    if point1 is None or point2 is None:
        return None
    return point1.distance(point2) * 111.32  # Approximate km per degree


def send_email_notification(subject, message, recipient_list, html_message=None):
    """
    Send email notification.
    """
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@agrilink.com'),
            recipient_list=recipient_list,
            html_message=html_message,
            fail_silently=False,
        )
        return True
    except Exception as e:
        logger.error(f"Failed to send email: {str(e)}")
        return False


def format_currency(amount, currency='USD'):
    """
    Format amount as currency.
    """
    if amount is None:
        return None
    return f'{currency} {amount:,.2f}'


def format_date(date, format_string='%Y-%m-%d'):
    """
    Format date string.
    """
    if date is None:
        return None
    return date.strftime(format_string)


def get_client_ip(request):
    """
    Get client IP address from request.
    """
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip


def get_user_agent(request):
    """
    Get user agent from request.
    """
    return request.META.get('HTTP_USER_AGENT', '')


def validate_file_size(file, max_size_mb=10):
    """
    Validate file size.
    """
    max_size_bytes = max_size_mb * 1024 * 1024
    if file.size > max_size_bytes:
        raise ValidationError(f'File size must be less than {max_size_mb}MB')
    return True


def validate_file_type(file, allowed_types):
    """
    Validate file type.
    """
    content_type = file.content_type
    if content_type not in allowed_types:
        raise ValidationError(f'File type {content_type} is not allowed')
    return True


def create_thumbnail(image_path, size=(200, 200)):
    """
    Create thumbnail for an image.
    """
    try:
        from PIL import Image
        import os

        img = Image.open(image_path)
        img.thumbnail(size)

        # Create thumbnail filename
        base, ext = os.path.splitext(image_path)
        thumbnail_path = f'{base}_thumb{ext}'

        img.save(thumbnail_path)
        return thumbnail_path
    except Exception as e:
        logger.error(f"Failed to create thumbnail: {str(e)}")
        return None


def sanitize_string(input_string):
    """
    Sanitize string input.
    """
    if not input_string:
        return ''
    return input_string.strip().lower()


def is_valid_phone_number(phone):
    """
    Validate phone number format.
    """
    import re
    pattern = r'^\+?1?\d{9,15}$'
    return bool(re.match(pattern, phone))


def is_valid_email(email):
    """
    Validate email format.
    """
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


def generate_otp(length=6):
    """
    Generate One-Time Password.
    """
    return ''.join(random.choices(string.digits, k=length))


def is_otp_valid(otp_created_at, expiry_minutes=10):
    """
    Check if OTP is still valid.
    """
    if otp_created_at is None:
        return False

    expiry_time = otp_created_at + timedelta(minutes=expiry_minutes)
    current_time = timezone.now()

    return current_time < expiry_time


def mask_sensitive_data(data, mask_char='*'):
    """
    Mask sensitive data for logging.
    """
    if isinstance(data, str) and len(data) > 4:
        return data[:2] + mask_char * (len(data) - 4) + data[-2:]
    return mask_char * 10


def calculate_age(birth_date):
    """
    Calculate age from birth date.
    """
    if birth_date is None:
        return None

    today = timezone.now().date()
    age = today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
    return age


def get_file_extension(filename):
    """
    Get file extension from filename.
    """
    import os
    return os.path.splitext(filename)[1].lower()


def is_image_file(filename):
    """
    Check if file is an image.
    """
    image_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
    return get_file_extension(filename) in image_extensions


def compress_image(image_path, quality=85):
    """
    Compress image to reduce file size.
    """
    try:
        from PIL import Image

        img = Image.open(image_path)

        # Convert to RGB if necessary
        if img.mode in ('RGBA', 'P'):
            img = img.convert('RGB')

        img.save(image_path, 'JPEG', quality=quality, optimize=True)
        return True
    except Exception as e:
        logger.error(f"Failed to compress image: {str(e)}")
        return False