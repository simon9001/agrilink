"""
Custom exceptions for AgriLink API.
"""
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
import logging

logger = logging.getLogger(__name__)


def custom_exception_handler(exc, context):
    """
    Custom exception handler for AgriLink API.
    """
    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)

    if response is not None:
        # Format the error response according to API standards
        custom_response_data = {
            'success': False,
            'error': {
                'code': exc.__class__.__name__,
                'message': str(exc),
            },
            'timestamp': '2024-01-01T00:00:00Z',  # This should be dynamic
        }

        # Add field-specific errors for validation errors
        if hasattr(exc, 'detail') and isinstance(exc.detail, dict):
            custom_response_data['error']['details'] = exc.detail

        response.data = custom_response_data

        # Log the error
        logger.error(f"API Error: {exc.__class__.__name__}: {str(exc)}")

    return response


class AgriLinkException(Exception):
    """
    Base exception class for AgriLink.
    """
    def __init__(self, message, status_code=status.HTTP_400_BAD_REQUEST):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class ValidationException(AgriLinkException):
    """
    Exception raised for validation errors.
    """
    def __init__(self, message, details=None):
        super().__init__(message, status.HTTP_400_BAD_REQUEST)
        self.details = details


class AuthenticationException(AgriLinkException):
    """
    Exception raised for authentication errors.
    """
    def __init__(self, message="Authentication failed"):
        super().__init__(message, status.HTTP_401_UNAUTHORIZED)


class AuthorizationException(AgriLinkException):
    """
    Exception raised for authorization errors.
    """
    def __init__(self, message="Permission denied"):
        super().__init__(message, status.HTTP_403_FORBIDDEN)


class NotFoundException(AgriLinkException):
    """
    Exception raised when a resource is not found.
    """
    def __init__(self, message="Resource not found"):
        super().__init__(message, status.HTTP_404_NOT_FOUND)


class ConflictException(AgriLinkException):
    """
    Exception raised when there's a conflict with the current state.
    """
    def __init__(self, message="Resource conflict"):
        super().__init__(message, status.HTTP_409_CONFLICT)


class RateLimitException(AgriLinkException):
    """
    Exception raised when rate limit is exceeded.
    """
    def __init__(self, message="Rate limit exceeded"):
        super().__init__(message, status.HTTP_429_TOO_MANY_REQUESTS)


class ServerException(AgriLinkException):
    """
    Exception raised for server errors.
    """
    def __init__(self, message="Internal server error"):
        super().__init__(message, status.HTTP_500_INTERNAL_SERVER_ERROR)


class ServiceUnavailableException(AgriLinkException):
    """
    Exception raised when a service is unavailable.
    """
    def __init__(self, message="Service temporarily unavailable"):
        super().__init__(message, status.HTTP_503_SERVICE_UNAVAILABLE)