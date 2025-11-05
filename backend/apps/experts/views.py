"""
Expert services views for AgriLink API.
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
from django.db.models import Q, Count, Avg

from core.permissions import IsExpert, IsFarmer, IsOwnerOrReadOnly, IsActiveUser
from core.pagination import StandardResultsSetPagination
from core.exceptions import ValidationException, NotFoundException, AuthorizationException
from .models import AdvicePost, AdvicePostLike, AdvicePostComment, Consultation, ConsultationReview
from .serializers import (
    AdvicePostSerializer,
    AdvicePostDetailSerializer,
    AdvicePostLikeSerializer,
    AdvicePostCommentSerializer,
    ConsultationSerializer,
    ConsultationStatusUpdateSerializer,
    ConsultationReviewSerializer,
    ExpertListSerializer,
)

User = get_user_model()


class ExpertListView(generics.ListAPIView):
    """
    List all available experts.
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = ExpertListSerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['expert_profile__specialization']
    search_fields = ['first_name', 'last_name', 'expert_profile__bio']
    ordering_fields = ['expert_profile__rating', 'expert_profile__years_experience']
    ordering = ['-expert_profile__rating']

    def get_queryset(self):
        """
        Get users with expert profiles.
        """
        return User.objects.filter(
            role=User.Role.EXPERT,
            is_active=True,
            expert_profile__isnull=False
        ).select_related('expert_profile').annotate(
            consultation_count=Count('expert_consultations')
        ).order_by('-expert_profile__rating', '-expert_profile__total_consultations')


class AdvicePostListCreateView(generics.ListCreateAPIView):
    """
    List and create advice posts.
    """
    serializer_class = AdvicePostSerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['category', 'target_audience', 'is_featured', 'is_published']
    search_fields = ['title', 'content', 'excerpt', 'tags']
    ordering_fields = ['created_at', 'published_at', 'view_count', 'likes_count']
    ordering = ['-published_at', '-created_at']

    def get_queryset(self):
        """
        Filter advice posts based on user and query parameters.
        """
        queryset = AdvicePost.objects.select_related('expert').prefetch_related('likes', 'comments')

        # Public users only see published posts
        if not self.request.user.is_authenticated:
            queryset = queryset.filter(is_published=True)

        # Filter by expert if specified
        expert_id = self.request.query_params.get('expert_id')
        if expert_id:
            queryset = queryset.filter(expert_id=expert_id)

        # Filter by category
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)

        # Filter by target audience
        target_audience = self.request.query_params.get('target_audience')
        if target_audience:
            queryset = queryset.filter(target_audience__contains=[target_audience])

        # Featured posts
        featured_only = self.request.query_params.get('featured_only')
        if featured_only == 'true':
            queryset = queryset.filter(is_featured=True)

        return queryset

    def get_permissions(self):
        """
        Set permissions based on request method.
        """
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated, IsExpert, IsActiveUser]
        return [permissions.AllowAny]

    def perform_create(self, serializer):
        """
        Create advice post with current user as expert.
        """
        serializer.save(expert=self.request.user)

    def create(self, request, *args, **kwargs):
        """
        Handle advice post creation.
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            post = serializer.save(expert=request.user)

            # Create activity log
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=request.user,
                activity_type='POST_CREATE',
                request=request,
                description=f"Published advice post: {post.title}",
                metadata={
                    'post_id': str(post.id),
                    'category': post.category,
                }
            )

            return Response({
                'success': True,
                'data': serializer.data,
                'message': 'Advice post created successfully',
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


class AdvicePostDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update, or delete advice post.
    """
    serializer_class = AdvicePostDetailSerializer
    lookup_field = 'slug'
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        """
        Get advice posts with related data.
        """
        return AdvicePost.objects.select_related('expert').prefetch_related(
            'likes', 'comments', 'comments__replies'
        )

    def retrieve(self, request, *args, **kwargs):
        """
        Retrieve advice post and increment view count.
        """
        post = self.get_object()

        # Increment view count
        post.increment_view_count()

        # Create activity log for non-owners
        if request.user != post.expert:
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=request.user if request.user.is_authenticated else None,
                activity_type='POST_VIEW',
                request=request,
                description=f"Viewed advice post: {post.title}",
                metadata={
                    'post_id': str(post.id),
                    'expert_id': str(post.expert.id),
                }
            )

        serializer = self.get_serializer(post)
        return Response({
            'success': True,
            'data': serializer.data,
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_200_OK)

    def get_permissions(self):
        """
        Set permissions based on request method.
        """
        if self.request.method in ['PUT', 'PATCH', 'DELETE']:
            return [permissions.IsAuthenticated, IsOwnerOrReadOnly, IsActiveUser]
        return [permissions.AllowAny]


class ConsultationListCreateView(generics.ListCreateAPIView):
    """
    List and create consultations.
    """
    serializer_class = ConsultationSerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['status', 'consultation_type', 'payment_status']
    search_fields = ['topic', 'description']
    ordering_fields = ['created_at', 'scheduled_date', 'status']
    ordering = ['-created_at']

    def get_queryset(self):
        """
        Filter consultations based on user role.
        """
        user = self.request.user

        if not user.is_authenticated:
            return Consultation.objects.none()

        queryset = Consultation.objects.select_related('expert', 'farmer')

        # Filter based on user role
        if user.role == User.Role.FARMER:
            queryset = queryset.filter(farmer=user)
        elif user.role == User.Role.EXPERT:
            queryset = queryset.filter(expert=user)
        elif user.role == User.Role.ADMIN:
            # Admin can see all consultations
            pass
        else:
            # Other roles can't see consultations
            queryset = queryset.none()

        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        # Filter by expert
        expert_id = self.request.query_params.get('expert_id')
        if expert_id:
            queryset = queryset.filter(expert_id=expert_id)

        # Filter by date range
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')

        if date_from:
            queryset = queryset.filter(scheduled_date__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(scheduled_date__date__lte=date_to)

        return queryset

    def get_permissions(self):
        """
        Set permissions based on request method.
        """
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated, IsFarmer, IsActiveUser]
        return [permissions.IsAuthenticated, IsActiveUser]

    def create(self, request, *args, **kwargs):
        """
        Handle consultation creation.
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            consultation = serializer.save()

            return Response({
                'success': True,
                'data': serializer.data,
                'message': 'Consultation requested successfully',
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


class ConsultationDetailView(generics.RetrieveUpdateAPIView):
    """
    Retrieve or update consultation details.
    """
    serializer_class = ConsultationSerializer
    lookup_field = 'id'
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]

    def get_queryset(self):
        """
        Get consultations based on user role.
        """
        user = self.request.user
        queryset = Consultation.objects.select_related('expert', 'farmer')

        if user.role == User.Role.FARMER:
            return queryset.filter(farmer=user)
        elif user.role == User.Role.EXPERT:
            return queryset.filter(expert=user)
        elif user.role == User.Role.ADMIN:
            return queryset
        else:
            return queryset.none()


class ConsultationStatusUpdateView(generics.UpdateAPIView):
    """
    Update consultation status.
    """
    serializer_class = ConsultationStatusUpdateSerializer
    lookup_field = 'id'
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]

    def get_queryset(self):
        """
        Get consultations that user can update.
        """
        user = self.request.user
        queryset = Consultation.objects.select_related('expert', 'farmer')

        if user.role == User.Role.EXPERT:
            return queryset.filter(expert=user)
        elif user.role == User.Role.FARMER:
            return queryset.filter(farmer=user)
        elif user.role == User.Role.ADMIN:
            return queryset
        else:
            return queryset.none()

    def update(self, request, *args, **kwargs):
        """
        Update consultation status with validation.
        """
        try:
            consultation = self.get_object()
            serializer = self.get_serializer(
                data=request.data,
                context={'consultation': consultation, 'request': request}
            )
            serializer.is_valid(raise_exception=True)

            new_status = serializer.validated_data['new_status']
            notes = serializer.validated_data.get('notes', '')
            payment_amount = serializer.validated_data.get('payment_amount')

            # Update consultation status
            old_status = consultation.status
            consultation.status = new_status

            # Set timestamps based on status
            if new_status == Consultation.Status.SCHEDULED:
                pass  # No specific timestamp needed
            elif new_status == Consultation.Status.IN_PROGRESS:
                consultation.start_consultation()
            elif new_status == Consultation.Status.COMPLETED:
                consultation.complete_consultation(
                    notes=notes,
                    recommendations=serializer.validated_data.get('recommendations', [])
                )
                # Set payment amount if provided
                if payment_amount:
                    consultation.total_amount = payment_amount
            elif new_status == Consultation.Status.CANCELLED:
                consultation.cancel_consultation(notes, request.user.role.lower())

            # Add notes
            if notes:
                if request.user == consultation.expert:
                    consultation.expert_notes = notes
                else:
                    consultation.farmer_notes = notes

            consultation.save()

            # Create activity log
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=request.user,
                activity_type='CONSULTATION_UPDATE',
                request=request,
                description=f"Updated consultation {consultation.id} from {old_status} to {new_status}",
                metadata={
                    'consultation_id': str(consultation.id),
                    'old_status': old_status,
                    'new_status': new_status,
                }
            )

            # Send notification to the other party
            from apps.notifications.models import Notification
            recipient = consultation.farmer if request.user == consultation.expert else consultation.expert
            Notification.objects.create(
                recipient=recipient,
                sender=request.user,
                title=f"Consultation {new_status.lower()}",
                message=f"Consultation status has been updated to {new_status}.",
                notification_type=Notification.Type.CONSULTATION,
                related_object_type=Notification.RelatedObjectType.CONSULTATION,
                related_object_id=consultation.id,
                action_url=f"/experts/consultations/{consultation.id}/",
            )

            return Response({
                'success': True,
                'data': ConsultationSerializer(consultation).data,
                'message': f'Consultation status updated to {new_status}',
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


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsActiveUser])
def like_advice_post(request, post_slug):
    """
    Like or unlike an advice post.
    """
    try:
        post = get_object_or_404(AdvicePost, slug=post_slug)

        # Check if user can like this post
        if post.expert == request.user:
            return Response({
                'success': False,
                'error': {
                    'code': 'CANNOT_LIKE_OWN_POST',
                    'message': 'You cannot like your own post.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_400_BAD_REQUEST)

        # Check if already liked
        existing_like = AdvicePostLike.objects.filter(post=post, user=request.user).first()

        if existing_like:
            # Unlike the post
            existing_like.delete()
            post.likes_count -= 1
            post.save(update_fields=['likes_count'])

            return Response({
                'success': True,
                'data': {'liked': False, 'likes_count': post.likes_count},
                'message': 'Post unliked successfully',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_200_OK)
        else:
            # Like the post
            AdvicePostLike.objects.create(post=post, user=request.user)
            post.likes_count += 1
            post.save(update_fields=['likes_count'])

            return Response({
                'success': True,
                'data': {'liked': True, 'likes_count': post.likes_count},
                'message': 'Post liked successfully',
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response({
            'success': False,
            'error': {
                'code': 'LIKE_ERROR',
                'message': 'Failed to process like request.',
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsActiveUser])
def comment_on_advice_post(request, post_slug):
    """
    Add a comment to an advice post.
    """
    try:
        post = get_object_or_404(AdvicePost, slug=post_slug)

        # Create serializer with post context
        serializer = AdvicePostCommentSerializer(
            data=request.data,
            context={'post': post, 'request': request}
        )
        serializer.is_valid(raise_exception=True)
        comment = serializer.save()

        # Update comment count
        post.comments_count += 1
        post.save(update_fields=['comments_count'])

        # Create activity log
        from apps.dashboard.models import UserActivity
        UserActivity.objects.create(
            user=request.user,
            activity_type='COMMENT',
            request=request,
            description=f"Commented on advice post: {post.title}",
            metadata={
                'post_id': str(post.id),
                'comment_id': str(comment.id),
            }
        )

        return Response({
            'success': True,
            'data': serializer.data,
            'message': 'Comment added successfully',
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
@permission_classes([permissions.IsAuthenticated, IsActiveUser])
def expert_statistics(request):
    """
    Get expert statistics for the current user.
    """
    try:
        user = request.user

        if user.role != User.Role.EXPERT:
            return Response({
                'success': False,
                'error': {
                    'code': 'NOT_EXPERT',
                    'message': 'This endpoint is only available for experts.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_403_FORBIDDEN)

        # Get expert statistics
        stats = {
            'expert': {
                'published_posts': AdvicePost.objects.filter(
                    expert=user, is_published=True
                ).count(),
                'total_views': AdvicePost.objects.filter(expert=user).aggregate(
                    total_views=Count('view_count')
                )['total_views'] or 0,
                'total_likes': AdvicePostLike.objects.filter(post__expert=user).count(),
                'total_comments': AdvicePostComment.objects.filter(post__expert=user).count(),
                'consultations': {
                    'total': Consultation.objects.filter(expert=user).count(),
                    'pending': Consultation.objects.filter(
                        expert=user, status=Consultation.Status.REQUESTED
                    ).count(),
                    'scheduled': Consultation.objects.filter(
                        expert=user, status=Consultation.Status.SCHEDULED
                    ).count(),
                    'completed': Consultation.objects.filter(
                        expert=user, status=Consultation.Status.COMPLETED
                    ).count(),
                    'upcoming': Consultation.objects.filter(
                        expert=user,
                        status__in=[Consultation.Status.SCHEDULED, Consultation.Status.REQUESTED],
                        scheduled_date__gt=timezone.now()
                    ).count(),
                },
                'earnings': {
                    'total': Consultation.objects.filter(
                        expert=user,
                        status=Consultation.Status.COMPLETED
                    ).aggregate(total=Count('total_amount'))['total'] or 0,
                    'this_month': Consultation.objects.filter(
                        expert=user,
                        status=Consultation.Status.COMPLETED,
                        completed_at__month=timezone.now().month,
                        completed_at__year=timezone.now().year
                    ).aggregate(total=Count('total_amount'))['total'] or 0,
                },
            }
        }

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
                'message': 'Failed to retrieve expert statistics.',
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsActiveUser])
def farmer_consultations(request):
    """
    Get consultations for the current farmer.
    """
    try:
        if request.user.role != User.Role.FARMER:
            return Response({
                'success': False,
                'error': {
                    'code': 'NOT_FARMER',
                    'message': 'This endpoint is only available for farmers.',
                },
                'timestamp': timezone.now().isoformat(),
            }, status=status.HTTP_403_FORBIDDEN)

        consultations = Consultation.objects.filter(
            farmer=request.user
        ).select_related('expert', 'expert__expert_profile').order_by('-created_at')

        # Apply filters
        status_filter = request.query_params.get('status')
        if status_filter:
            consultations = consultations.filter(status=status_filter)

        # Pagination
        page = request.query_params.get('page', 1)
        paginator = StandardResultsSetPagination()
        result_page = paginator.paginate_queryset(consultations, request)

        serializer = ConsultationSerializer(result_page, many=True)

        return paginator.get_paginated_response({
            'success': True,
            'data': serializer.data,
            'timestamp': timezone.now().isoformat(),
        })

    except Exception as e:
        return Response({
            'success': False,
            'error': {
                'code': 'CONSULTATIONS_ERROR',
                'message': 'Failed to retrieve consultations.',
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)