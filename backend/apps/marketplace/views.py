"""
Marketplace views for AgriLink API.
"""
from rest_framework import status, permissions, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import Distance as D
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from core.permissions import IsFarmer, IsBuyer, IsOwnerOrReadOnly, IsActiveUser
from core.pagination import StandardResultsSetPagination
from core.exceptions import ValidationException, NotFoundException, AuthorizationException

from .models import ProduceCategory, ProduceListing, ListingInquiry, ListingReview
from .serializers import (
    ProduceCategorySerializer,
    ProduceListingSerializer,
    ProduceListingDetailSerializer,
    ListingInquirySerializer,
    ListingReviewSerializer,
    ListingSearchSerializer,
)

User = get_user_model()


class CategoryListView(generics.ListAPIView):
    """
    List all produce categories.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = ProduceCategorySerializer
    queryset = ProduceCategory.objects.filter(is_active=True)
    pagination_class = None


class ProduceListingListCreateView(generics.ListCreateAPIView):
    """
    List and create produce listings.
    """
    serializer_class = ProduceListingSerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['category', 'quality_grade', 'is_organic', 'status']
    search_fields = ['product_name', 'variety', 'description']
    ordering_fields = ['created_at', 'unit_price', 'quantity_available', 'view_count']
    ordering = ['-created_at']

    def get_queryset(self):
        """
        Filter queryset based on user role and query parameters.
        """
        queryset = ProduceListing.objects.select_related('farmer').prefetch_related('reviews')

        # For buyers and public users, only show active listings
        if not self.request.user.is_authenticated or self.request.user.role != User.Role.FARMER:
            queryset = queryset.filter(status=ProduceListing.Status.ACTIVE)

        # Filter by farmer if specified
        farmer_id = self.request.query_params.get('farmer_id')
        if farmer_id:
            queryset = queryset.filter(farmer_id=farmer_id)

        # Geographic filtering
        latitude = self.request.query_params.get('latitude')
        longitude = self.request.query_params.get('longitude')
        radius_km = self.request.query_params.get('radius_km', 50)

        if latitude and longitude:
            user_location = Point(float(longitude), float(latitude), srid=4326)
            queryset = queryset.annotate(
                distance=Distance('location', user_location)
            ).filter(
                distance__lte=D(km=radius_km)
            ).order_by('distance')

        # Price filtering
        price_min = self.request.query_params.get('price_min')
        price_max = self.request.query_params.get('price_max')
        if price_min:
            queryset = queryset.filter(unit_price__gte=price_min)
        if price_max:
            queryset = queryset.filter(unit_price__lte=price_max)

        # Quality filtering
        quality_grade = self.request.query_params.get('quality_grade')
        if quality_grade:
            queryset = queryset.filter(quality_grade=quality_grade)

        # Organic filtering
        organic_only = self.request.query_params.get('organic_only')
        if organic_only == 'true':
            queryset = queryset.filter(is_organic=True)

        # Featured listings
        featured_only = self.request.query_params.get('featured_only')
        if featured_only == 'true':
            queryset = queryset.filter(is_featured=True)

        return queryset

    def get_permissions(self):
        """
        Set permissions based on request method.
        """
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated, IsFarmer, IsActiveUser]
        return [permissions.AllowAny]

    def perform_create(self, serializer):
        """
        Create listing with current user as farmer.
        """
        serializer.save(farmer=self.request.user)

    def create(self, request, *args, **kwargs):
        """
        Handle listing creation with activity logging.
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            listing = serializer.save(farmer=request.user)

            # Create activity log
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=request.user,
                activity_type='LISTING_CREATE',
                request=request,
                description=f"Created listing: {listing.product_name}",
                metadata={
                    'listing_id': str(listing.id),
                    'category': listing.category,
                    'quantity': float(listing.quantity_available),
                    'price': float(listing.unit_price),
                }
            )

            return Response({
                'success': True,
                'data': serializer.data,
                'message': 'Listing created successfully',
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


class ProduceListingDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update, or delete a produce listing.
    """
    serializer_class = ProduceListingDetailSerializer
    lookup_field = 'id'

    def get_queryset(self):
        """
        Get listing with related data.
        """
        return ProduceListing.objects.select_related('farmer').prefetch_related(
            'reviews', 'inquiries', 'orders'
        )

    def get_permissions(self):
        """
        Set permissions based on request method.
        """
        if self.request.method in ['PUT', 'PATCH', 'DELETE']:
            return [permissions.IsAuthenticated, IsOwnerOrReadOnly, IsActiveUser]
        return [permissions.AllowAny]

    def retrieve(self, request, *args, **kwargs):
        """
        Retrieve listing details and increment view count.
        """
        listing = self.get_object()

        # Increment view count
        listing.increment_view_count()

        # Create activity log for non-owners
        if request.user != listing.farmer:
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=request.user if request.user.is_authenticated else None,
                activity_type='LISTING_VIEW',
                request=request,
                description=f"Viewed listing: {listing.product_name}",
                metadata={
                    'listing_id': str(listing.id),
                    'farmer_id': str(listing.farmer.id),
                }
            )

        serializer = self.get_serializer(listing)
        return Response({
            'success': True,
            'data': serializer.data,
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_200_OK)

    def update(self, request, *args, **kwargs):
        """
        Update listing with validation.
        """
        try:
            partial = kwargs.pop('partial', False)
            instance = self.get_object()

            # Check if user owns the listing
            if instance.farmer != request.user:
                raise AuthorizationException("You can only update your own listings")

            serializer = self.get_serializer(instance, data=request.data, partial=partial)
            serializer.is_valid(raise_exception=True)
            listing = serializer.save()

            # Create activity log
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=request.user,
                activity_type='PROFILE_UPDATE',
                request=request,
                description=f"Updated listing: {listing.product_name}",
                metadata={
                    'listing_id': str(listing.id),
                    'updated_fields': list(request.data.keys()),
                }
            )

            return Response({
                'success': True,
                'data': serializer.data,
                'message': 'Listing updated successfully',
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

    def destroy(self, request, *args, **kwargs):
        """
        Delete listing (soft delete by changing status).
        """
        instance = self.get_object()

        # Check if user owns the listing
        if instance.farmer != request.user:
            raise AuthorizationException("You can only delete your own listings")

        # Soft delete by changing status
        instance.status = ProduceListing.Status.CANCELLED
        instance.save()

        return Response({
            'success': True,
            'message': 'Listing deleted successfully',
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_200_OK)


class ProduceListingUpdateView(generics.UpdateAPIView):
    """
    Update produce listing (alias for detail view).
    """
    serializer_class = ProduceListingSerializer
    lookup_field = 'id'
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly, IsActiveUser]

    def get_queryset(self):
        return ProduceListing.objects.filter(farmer=self.request.user)


class ProduceListingDeleteView(generics.DestroyAPIView):
    """
    Delete produce listing.
    """
    lookup_field = 'id'
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly, IsActiveUser]

    def get_queryset(self):
        return ProduceListing.objects.filter(farmer=self.request.user)

    def perform_destroy(self, instance):
        """
        Soft delete listing.
        """
        instance.status = ProduceListing.Status.CANCELLED
        instance.save()


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsBuyer, IsActiveUser])
def create_listing_inquiry(request, listing_id):
    """
    Create an inquiry for a produce listing.
    """
    try:
        listing = get_object_or_404(ProduceListing, id=listing_id)

        # Create serializer with listing context
        serializer = ListingInquirySerializer(
            data=request.data,
            context={'listing': listing, 'request': request}
        )
        serializer.is_valid(raise_exception=True)
        inquiry = serializer.save()

        # Send notification to farmer
        from apps.notifications.models import Notification
        Notification.objects.create(
            recipient=listing.farmer,
            sender=request.user,
            title=f"New inquiry for {listing.product_name}",
            message=f"{request.user.full_name} is interested in your {listing.product_name} listing.",
            notification_type=Notification.Type.INQUIRY_RESPONSE,
            related_object_type=Notification.RelatedObjectType.LISTING,
            related_object_id=listing.id,
            action_url=f"/marketplace/listings/{listing.id}/",
        )

        return Response({
            'success': True,
            'data': serializer.data,
            'message': 'Inquiry sent successfully',
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_201_CREATED)

    except ValidationException as e:
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': str(e),
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsFarmer, IsActiveUser])
def my_listings(request):
    """
    Get current user's produce listings.
    """
    try:
        listings = ProduceListing.objects.filter(farmer=request.user).order_by('-created_at')

        # Apply filters
        status_filter = request.query_params.get('status')
        if status_filter:
            listings = listings.filter(status=status_filter)

        # Pagination
        page = request.query_params.get('page', 1)
        paginator = StandardResultsSetPagination()
        result_page = paginator.paginate_queryset(listings, request)

        serializer = ProduceListingSerializer(result_page, many=True)

        return paginator.get_paginated_response({
            'success': True,
            'data': serializer.data,
            'timestamp': timezone.now().isoformat(),
        })

    except Exception as e:
        return Response({
            'success': False,
            'error': {
                'code': 'LISTINGS_ERROR',
                'message': 'Failed to retrieve listings.',
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsActiveUser])
def create_listing_review(request, listing_id):
    """
    Create a review for a produce listing.
    """
    try:
        listing = get_object_or_404(ProduceListing, id=listing_id)

        # Check if user can review (must have interacted with the listing)
        # This is a simplified check - in production, verify actual purchase/interaction
        from apps.orders.models import Order
        has_ordered = Order.objects.filter(
            buyer=request.user,
            listing=listing,
            status=Order.Status.DELIVERED
        ).exists()

        if not has_ordered and request.user != listing.farmer:
            return Response({
                'success': False,
                'error': {
                    'code': 'REVIEW_NOT_ALLOWED',
                    'message': 'You can only review listings you have purchased.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_403_FORBIDDEN)

        # Create serializer with listing context
        serializer = ListingReviewSerializer(
            data=request.data,
            context={'listing': listing, 'request': request}
        )
        serializer.is_valid(raise_exception=True)
        review = serializer.save()

        # Send notification to farmer
        from apps.notifications.models import Notification
        Notification.objects.create(
            recipient=listing.farmer,
            sender=request.user,
            title=f"New review for {listing.product_name}",
            message=f"{request.user.full_name} left a review for your listing.",
            notification_type=Notification.Type.REVIEW,
            related_object_type=Notification.RelatedObjectType.LISTING,
            related_object_id=listing.id,
            action_url=f"/marketplace/listings/{listing.id}/",
        )

        return Response({
            'success': True,
            'data': serializer.data,
            'message': 'Review posted successfully',
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_201_CREATED)

    except ValidationException as e:
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': str(e),
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def search_listings(request):
    """
    Search produce listings with advanced filtering.
    """
    try:
        # Validate search parameters
        search_serializer = ListingSearchSerializer(data=request.query_params)
        search_serializer.is_valid(raise_exception=True)

        # Get search parameters
        search_params = search_serializer.validated_data

        # Start with base queryset
        queryset = ProduceListing.objects.filter(
            status=ProduceListing.Status.ACTIVE
        ).select_related('farmer')

        # Apply filters
        if search_params.get('category'):
            queryset = queryset.filter(category=search_params['category'])

        if search_params.get('organic_only'):
            queryset = queryset.filter(is_organic=True)

        if search_params.get('quality_grade'):
            queryset = queryset.filter(quality_grade=search_params['quality_grade'])

        if search_params.get('price_min'):
            queryset = queryset.filter(unit_price__gte=search_params['price_min'])

        if search_params.get('price_max'):
            queryset = queryset.filter(unit_price__lte=search_params['price_max'])

        # Geographic search
        if search_params.get('latitude') and search_params.get('longitude'):
            user_location = Point(
                search_params['longitude'],
                search_params['latitude'],
                srid=4326
            )
            radius_km = search_params.get('radius_km', 50)

            queryset = queryset.annotate(
                distance=Distance('location', user_location)
            ).filter(
                distance__lte=D(km=radius_km)
            )

            if search_params.get('sort_by') == 'distance':
                queryset = queryset.order_by('distance')

        # Farmer rating filter
        if search_params.get('farmer_rating_min'):
            from django.db.models import Avg
            queryset = queryset.annotate(
                farmer_avg_rating=Avg('farmer__reviews_received__rating')
            ).filter(
                farmer_avg_rating__gte=search_params['farmer_rating_min']
            )

        # Apply sorting
        sort_by = search_params.get('sort_by', 'newest')
        if sort_by == 'newest':
            queryset = queryset.order_by('-created_at')
        elif sort_by == 'price_low':
            queryset = queryset.order_by('unit_price')
        elif sort_by == 'price_high':
            queryset = queryset.order_by('-unit_price')
        elif sort_by == 'rating':
            from django.db.models import Avg
            queryset = queryset.annotate(
                avg_rating=Avg('reviews__rating')
            ).order_by('-avg_rating', '-created_at')

        # Paginate results
        paginator = StandardResultsSetPagination()
        result_page = paginator.paginate_queryset(queryset, request)

        serializer = ProduceListingSerializer(result_page, many=True)

        return paginator.get_paginated_response({
            'success': True,
            'data': serializer.data,
            'search_params': search_params,
            'timestamp': timezone.now().isoformat(),
        })

    except ValidationException as e:
        return Response({
            'success': False,
            'error': {
                'code': 'VALIDATION_ERROR',
                'message': str(e),
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def featured_listings(request):
    """
    Get featured produce listings.
    """
    try:
        limit = int(request.query_params.get('limit', 10))
        limit = min(limit, 50)  # Cap at 50

        listings = ProduceListing.objects.filter(
            status=ProduceListing.Status.ACTIVE,
            is_featured=True
        ).select_related('farmer').order_by('-created_at')[:limit]

        serializer = ProduceListingSerializer(listings, many=True)

        return Response({
            'success': True,
            'data': serializer.data,
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'success': False,
            'error': {
                'code': 'FEATURED_LISTINGS_ERROR',
                'message': 'Failed to retrieve featured listings.',
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)