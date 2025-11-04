"""
User management URLs for AgriLink API.
"""
from django.urls import path
from .views import (
    UserProfileView,
    UserProfileUpdateView,
    PublicProfileView,
    UserListView,
    UserStatusUpdateView,
)

urlpatterns = [
    # Profile Management
    path('profile/', UserProfileView.as_view(), name='user_profile'),
    path('profile/update/', UserProfileUpdateView.as_view(), name='user_profile_update'),
    path('<uuid:user_id>/profile/', PublicProfileView.as_view(), name='public_profile'),

    # User Management (Admin)
    path('', UserListView.as_view(), name='user_list'),
    path('<uuid:user_id>/status/', UserStatusUpdateView.as_view(), name='user_status_update'),
]