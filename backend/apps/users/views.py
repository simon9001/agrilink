"""
User profile views for AgriLink API.
"""
from rest_framework import status, permissions, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from core.permissions import IsAdmin, IsOwnerOrReadOnly, IsActiveUser
from core.pagination import StandardResultsSetPagination
from core.exceptions import ValidationException, NotFoundException, AuthorizationException

from .models import FarmerProfile, BuyerProfile, SupplierProfile, ExpertProfile
from .serializers import (
    UserProfileSerializer,
    UpdateProfileSerializer,
    PublicProfileSerializer,
    UserListSerializer,
    LocationUpdateSerializer,
    FarmerProfileSerializer,
    BuyerProfileSerializer,
    SupplierProfileSerializer,
    ExpertProfileSerializer,
)

User = get_user_model()


class UserProfileView(generics.RetrieveUpdateAPIView):
    """
    Get or update current user's complete profile.
    """
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]
    serializer_class = UserProfileSerializer

    def get_object(self):
        """
        Return current user.
        """
        return self.request.user

    def update(self, request, *args, **kwargs):
        """
        Update user profile with role-specific data.
        """
        try:
            instance = self.get_object()
            serializer = UpdateProfileSerializer(instance, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            user = serializer.save()

            # Create activity log
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=user,
                activity_type='PROFILE_UPDATE',
                request=request,
                description="User updated profile",
                metadata={'updated_fields': list(request.data.keys())}
            )

            return Response({
                'success': True,
                'data': UserProfileSerializer(user).data,
                'message': 'Profile updated successfully',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)

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
                    'code': 'PROFILE_UPDATE_ERROR',
                    'message': 'Failed to update profile. Please try again.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class UserProfileUpdateView(generics.UpdateAPIView):
    """
    Update current user's profile (alias for UserProfileView).
    """
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]
    serializer_class = UpdateProfileSerializer

    def get_object(self):
        """
        Return current user.
        """
        return self.request.user


class PublicProfileView(generics.RetrieveAPIView):
    """
    Get public profile information for a user.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = PublicProfileSerializer
    lookup_field = 'id'
    queryset = User.objects.filter(is_active=True)


class LocationUpdateView(generics.GenericAPIView):
    """
    Update user location coordinates.
    """
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]
    serializer_class = LocationUpdateSerializer

    def post(self, request, *args, **kwargs):
        """
        Update user location.
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            user = serializer.save(user=request.user)

            # Create activity log
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=user,
                activity_type='PROFILE_UPDATE',
                request=request,
                description="User updated location",
                metadata={
                    'latitude': float(serializer.validated_data['latitude']),
                    'longitude': float(serializer.validated_data['longitude']),
                }
            )

            return Response({
                'success': True,
                'data': {
                    'location': user.get_location_coordinates(),
                    'address': user.location_address,
                },
                'message': 'Location updated successfully',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)

        except ValidationException as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'VALIDATION_ERROR',
                    'message': str(e),
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_400_BAD_REQUEST)


class UserListView(generics.ListAPIView):
    """
    List users (admin only).
    """
    permission_classes = [permissions.IsAuthenticated, IsAdmin]
    serializer_class = UserListSerializer
    queryset = User.objects.all()
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['role', 'is_active', 'is_verified']
    search_fields = ['email', 'first_name', 'last_name']
    ordering_fields = ['created_at', 'last_login', 'email']
    ordering = ['-created_at']

    def get_queryset(self):
        """
        Filter queryset based on query parameters.
        """
        queryset = super().get_queryset()

        # Date range filtering
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')

        if start_date:
            queryset = queryset.filter(created_at__gte=start_date)
        if end_date:
            queryset = queryset.filter(created_at__lte=end_date)

        return queryset


class UserStatusUpdateView(generics.UpdateAPIView):
    """
    Update user status (admin only).
    """
    permission_classes = [permissions.IsAuthenticated, IsAdmin]
    serializer_class = UserListSerializer
    queryset = User.objects.all()
    lookup_field = 'id'

    def update(self, request, *args, **kwargs):
        """
        Update user status (active, verified, etc.).
        """
        try:
            user = self.get_object()
            data = request.data

            # Update fields
            if 'is_active' in data:
                user.is_active = data['is_active']
            if 'is_verified' in data:
                user.is_verified = data['is_verified']
            if 'admin_notes' in data:
                # Note: This would require adding admin_notes field to User model
                pass

            user.save()

            # Create activity log
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=user,
                activity_type='SYSTEM',
                request=request,
                description=f"Admin updated user status",
                metadata={
                    'admin': request.user.id,
                    'updated_fields': list(data.keys()),
                }
            )

            return Response({
                'success': True,
                'data': UserListSerializer(user).data,
                'message': 'User status updated successfully',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'STATUS_UPDATE_ERROR',
                    'message': 'Failed to update user status.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Role-specific profile views
class FarmerProfileDetailView(generics.RetrieveUpdateAPIView):
    """
    Get or update farmer profile.
    """
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]
    serializer_class = FarmerProfileSerializer

    def get_object(self):
        """
        Get farmer profile for current user.
        """
        if self.request.user.role != User.Role.FARMER:
            raise AuthorizationException("Only farmers can access this endpoint")

        try:
            return self.request.user.farmer_profile
        except FarmerProfile.DoesNotExist:
            raise NotFoundException("Farmer profile not found. Please complete your profile.")

    def update(self, request, *args, **kwargs):
        """
        Update farmer profile.
        """
        try:
            instance = self.get_object()
            serializer = self.get_serializer(instance, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            profile = serializer.save()

            # Create activity log
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=request.user,
                activity_type='PROFILE_UPDATE',
                request=request,
                description="Farmer updated profile",
            )

            return Response({
                'success': True,
                'data': serializer.data,
                'message': 'Farmer profile updated successfully',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)

        except ValidationException as e:
            return Response({
                'success': False,
                'error': {
                    'code': 'VALIDATION_ERROR',
                    'message': str(e),
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_400_BAD_REQUEST)


class BuyerProfileDetailView(generics.RetrieveUpdateAPIView):
    """
    Get or update buyer profile.
    """
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]
    serializer_class = BuyerProfileSerializer

    def get_object(self):
        """
        Get buyer profile for current user.
        """
        if self.request.user.role != User.Role.BUYER:
            raise AuthorizationException("Only buyers can access this endpoint")

        try:
            return self.request.user.buyer_profile
        except BuyerProfile.DoesNotExist:
            raise NotFoundException("Buyer profile not found. Please complete your profile.")


class SupplierProfileDetailView(generics.RetrieveUpdateAPIView):
    """
    Get or update supplier profile.
    """
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]
    serializer_class = SupplierProfileSerializer

    def get_object(self):
        """
        Get supplier profile for current user.
        """
        if self.request.user.role != User.Role.SUPPLIER:
            raise AuthorizationException("Only suppliers can access this endpoint")

        try:
            return self.request.user.supplier_profile
        except SupplierProfile.DoesNotExist:
            raise NotFoundException("Supplier profile not found. Please complete your profile.")


class ExpertProfileDetailView(generics.RetrieveUpdateAPIView):
    """
    Get or update expert profile.
    """
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]
    serializer_class = ExpertProfileSerializer

    def get_object(self):
        """
        Get expert profile for current user.
        """
        if self.request.user.role != User.Role.EXPERT:
            raise AuthorizationException("Only experts can access this endpoint")

        try:
            return self.request.user.expert_profile
        except ExpertProfile.DoesNotExist:
            raise NotFoundException("Expert profile not found. Please complete your profile.")


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsActiveUser])
def complete_profile(request):
    """
    Complete user profile setup.
    """
    try:
        user = request.user
        role = user.role

        # Check if profile is already completed
        if user.has_profile():
            return Response({
                'success': False,
                'error': {
                    'code': 'PROFILE_ALREADY_COMPLETED',
                    'message': 'Profile is already completed.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_400_BAD_REQUEST)

        profile_data = request.data.get('profile_data', {})

        # Create role-specific profile
        if role == User.Role.FARMER:
            serializer = FarmerProfileSerializer(data=profile_data)
        elif role == User.Role.BUYER:
            serializer = BuyerProfileSerializer(data=profile_data)
        elif role == User.Role.SUPPLIER:
            serializer = SupplierProfileSerializer(data=profile_data)
        elif role == User.Role.EXPERT:
            serializer = ExpertProfileSerializer(data=profile_data)
        else:
            return Response({
                'success': False,
                'error': {
                    'code': 'INVALID_ROLE',
                    'message': 'Invalid user role for profile completion.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_400_BAD_REQUEST)

        serializer.is_valid(raise_exception=True)
        profile = serializer.save(user=user)

        # Create activity log
        from apps.dashboard.models import UserActivity
        UserActivity.objects.create(
            user=user,
            activity_type='PROFILE_UPDATE',
            request=request,
            description="User completed profile setup",
        )

        return Response({
            'success': True,
            'data': {
                'profile_completed': True,
                'role_profile': serializer.data,
            },
            'message': 'Profile completed successfully',
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


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsActiveUser])
def profile_statistics(request):
    """
    Get profile statistics for current user.
    """
    try:
        user = request.user
        stats = {
            'user': {
                'member_since': user.created_at,
                'last_login': user.last_login,
                'profile_completed': user.has_profile(),
                'is_verified': user.is_verified,
            }
        }

        # Add role-specific statistics
        if user.role == User.Role.FARMER and hasattr(user, 'farmer_profile'):
            from apps.marketplace.models import ProduceListing
            from apps.orders.models import Order

            farmer_stats = {
                'active_listings': ProduceListing.objects.filter(
                    farmer=user, status=ProduceListing.Status.ACTIVE
                ).count(),
                'total_listings': ProduceListing.objects.filter(farmer=user).count(),
                'total_orders': Order.objects.filter(seller=user).count(),
                'completed_orders': Order.objects.filter(
                    seller=user, status=Order.Status.DELIVERED
                ).count(),
            }
            stats['farmer'] = farmer_stats

        elif user.role == User.Role.BUYER and hasattr(user, 'buyer_profile'):
            from apps.orders.models import Order

            buyer_stats = {
                'total_orders': Order.objects.filter(buyer=user).count(),
                'completed_orders': Order.objects.filter(
                    buyer=user, status=Order.Status.DELIVERED
                ).count(),
                'pending_orders': Order.objects.filter(
                    buyer=user, status=Order.Status.PENDING
                ).count(),
            }
            stats['buyer'] = buyer_stats

        elif user.role == User.Role.EXPERT and hasattr(user, 'expert_profile'):
            from apps.experts.models import AdvicePost, Consultation

            expert_stats = {
                'published_posts': AdvicePost.objects.filter(
                    expert=user, is_published=True
                ).count(),
                'total_consultations': Consultation.objects.filter(expert=user).count(),
                'completed_consultations': Consultation.objects.filter(
                    expert=user, status=Consultation.Status.COMPLETED
                ).count(),
            }
            stats['expert'] = expert_stats

        elif user.role == User.Role.SUPPLIER and hasattr(user, 'supplier_profile'):
            from apps.suppliers.models import SupplierProduct, SupplierInquiry

            supplier_stats = {
                'active_products': SupplierProduct.objects.filter(
                    supplier=user, status=SupplierProduct.Status.ACTIVE
                ).count(),
                'total_products': SupplierProduct.objects.filter(supplier=user).count(),
                'inquiries_received': SupplierInquiry.objects.filter(supplier=user).count(),
            }
            stats['supplier'] = supplier_stats

        return Response({
            'success': True,
            'data': stats,
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'success': False,
            'error': {
                'code': 'STATISTICS_ERROR',
                'message': 'Failed to get profile statistics.',
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)