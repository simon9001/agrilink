"""
Custom permissions for AgriLink API.
"""
from rest_framework import permissions
from django.contrib.auth import get_user_model

User = get_user_model()


class IsOwner(permissions.BasePermission):
    """
    Custom permission to only allow owners of an object to edit it.
    """
    def has_object_permission(self, request, view, obj):
        # Permissions are only allowed to the owner of the object
        return obj.user == request.user


class IsFarmer(permissions.BasePermission):
    """
    Custom permission to only allow farmers to access the resource.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == User.Role.FARMER
        )


class IsBuyer(permissions.BasePermission):
    """
    Custom permission to only allow buyers to access the resource.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == User.Role.BUYER
        )


class IsSupplier(permissions.BasePermission):
    """
    Custom permission to only allow suppliers to access the resource.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == User.Role.SUPPLIER
        )


class IsExpert(permissions.BasePermission):
    """
    Custom permission to only allow experts to access the resource.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == User.Role.EXPERT
        )


class IsAdmin(permissions.BasePermission):
    """
    Custom permission to only allow admins to access the resource.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == User.Role.ADMIN
        )


class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow owners of an object to edit it.
    Read-only access is allowed for any authenticated user.
    """
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any request,
        # so we'll always allow GET, HEAD or OPTIONS requests.
        if request.method in permissions.SAFE_METHODS:
            return True

        # Write permissions are only allowed to the owner of the object
        return obj.user == request.user


class IsParticipantOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow participants of an object to edit it.
    Read-only access is allowed for any authenticated user.
    """
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any request,
        # so we'll always allow GET, HEAD or OPTIONS requests.
        if request.method in permissions.SAFE_METHODS:
            return True

        # Check if user is a participant (buyer or seller)
        return (
            hasattr(obj, 'buyer') and obj.buyer == request.user or
            hasattr(obj, 'seller') and obj.seller == request.user or
            hasattr(obj, 'user') and obj.user == request.user
        )


class IsPubliclyAccessible(permissions.BasePermission):
    """
    Allows access to public resources without authentication.
    """
    def has_permission(self, request, view):
        return True


class IsVerifiedUser(permissions.BasePermission):
    """
    Custom permission to only allow verified users to access the resource.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.is_verified
        )


class IsActiveUser(permissions.BasePermission):
    """
    Custom permission to only allow active users to access the resource.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.is_active
        )