"""
Authentication URLs for AgriLink API.
"""
from django.urls import path, include
from rest_framework_simplejwt.views import (
    TokenRefreshView,
    TokenObtainPairView,
    TokenBlacklistView,
)

from .views import (
    RegisterView,
    LoginView,
    LogoutView,
    PasswordResetView,
    PasswordResetConfirmView,
    EmailVerificationView,
    ResendVerificationView,
)

urlpatterns = [
    # JWT Authentication
    path('login/', LoginView.as_view(), name='login'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('register/', RegisterView.as_view(), name='register'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('token/blacklist/', TokenBlacklistView.as_view(), name='token_blacklist'),

    # Email Verification
    path('verify-email/', EmailVerificationView.as_view(), name='verify_email'),
    path('resend-verification/', ResendVerificationView.as_view(), name='resend_verification'),

    # Password Reset
    path('password-reset/', PasswordResetView.as_view(), name='password_reset'),
    path('password-reset-confirm/', PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
]