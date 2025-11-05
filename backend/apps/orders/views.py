"""
Order management views for AgriLink API.
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
from django.db.models import Q, Sum, Avg, Count

from core.permissions import IsBuyer, IsFarmer, IsParticipantOrReadOnly, IsActiveUser
from core.pagination import StandardResultsSetPagination
from core.exceptions import ValidationException, NotFoundException, AuthorizationException
from .models import Order, OrderItem, OrderTracking, OrderReview, Payment
from .serializers import (
    OrderSerializer,
    OrderCreateSerializer,
    OrderDetailSerializer,
    OrderStatusUpdateSerializer,
    OrderPaymentSerializer,
    OrderReviewSerializer,
    OrderSearchSerializer,
)

User = get_user_model()


class OrderListCreateView(generics.ListCreateAPIView):
    """
    List and create orders.
    """
    pagination_class = StandardResultsSetPagination
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['status', 'payment_status', 'payment_method']
    search_fields = ['order_number', 'product_name', 'buyer_notes']
    ordering_fields = ['created_at', 'final_amount', 'delivery_date']
    ordering = ['-created_at']

    def get_serializer_class(self):
        """
        Return appropriate serializer based on request method.
        """
        if self.request.method == 'POST':
            return OrderCreateSerializer
        return OrderSerializer

    def get_queryset(self):
        """
        Filter orders based on user role.
        """
        user = self.request.user

        if not user.is_authenticated:
            return Order.objects.none()

        queryset = Order.objects.select_related('buyer', 'seller', 'listing').prefetch_related(
            'items', 'tracking_updates', 'payments'
        )

        # Filter based on user role
        if user.role == User.Role.BUYER:
            queryset = queryset.filter(buyer=user)
        elif user.role == User.Role.FARMER:
            queryset = queryset.filter(seller=user)
        elif user.role == User.Role.ADMIN:
            # Admin can see all orders
            pass
        else:
            # Other roles can't see orders
            queryset = queryset.none()

        # Apply additional filters
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')

        if date_from:
            queryset = queryset.filter(created_at__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(created_at__date__lte=date_to)

        min_amount = self.request.query_params.get('min_amount')
        max_amount = self.request.query_params.get('max_amount')

        if min_amount:
            queryset = queryset.filter(final_amount__gte=min_amount)
        if max_amount:
            queryset = queryset.filter(final_amount__lte=max_amount)

        return queryset

    def get_permissions(self):
        """
        Set permissions based on request method.
        """
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated, IsBuyer, IsActiveUser]
        return [permissions.IsAuthenticated, IsActiveUser]

    def create(self, request, *args, **kwargs):
        """
        Create new order with validation and notifications.
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            order = serializer.save()

            # Create activity log
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=request.user,
                activity_type='ORDER_PLACE',
                request=request,
                description=f"Placed order {order.order_number}",
                metadata={
                    'order_id': str(order.id),
                    'seller_id': str(order.seller.id),
                    'amount': float(order.final_amount),
                }
            )

            # Send notification to seller
            from apps.notifications.models import Notification
            Notification.objects.create(
                recipient=order.seller,
                sender=request.user,
                title=f"New order: {order.order_number}",
                message=f"{request.user.full_name} placed an order for {order.product_name}.",
                notification_type=Notification.Type.ORDER_UPDATE,
                related_object_type=Notification.RelatedObjectType.ORDER,
                related_object_id=order.id,
                action_url=f"/orders/{order.id}/",
            )

            return Response({
                'success': True,
                'data': OrderDetailSerializer(order).data,
                'message': 'Order placed successfully',
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


class OrderDetailView(generics.RetrieveAPIView):
    """
    Retrieve order details.
    """
    serializer_class = OrderDetailSerializer
    lookup_field = 'id'
    permission_classes = [permissions.IsAuthenticated, IsParticipantOrReadOnly, IsActiveUser]

    def get_queryset(self):
        """
        Get orders with related data.
        """
        user = self.request.user
        queryset = Order.objects.select_related('buyer', 'seller', 'listing').prefetch_related(
            'items', 'tracking_updates', 'payments', 'review'
        )

        if user.role == User.Role.BUYER:
            return queryset.filter(buyer=user)
        elif user.role == User.Role.FARMER:
            return queryset.filter(seller=user)
        elif user.role == User.Role.ADMIN:
            return queryset
        else:
            return queryset.none()


class OrderStatusUpdateView(generics.UpdateAPIView):
    """
    Update order status.
    """
    serializer_class = OrderStatusUpdateSerializer
    lookup_field = 'id'
    permission_classes = [permissions.IsAuthenticated, IsParticipantOrReadOnly, IsActiveUser]

    def get_queryset(self):
        """
        Get orders that user can update.
        """
        user = self.request.user
        queryset = Order.objects.select_related('buyer', 'seller')

        if user.role == User.Role.FARMER:
            return queryset.filter(seller=user)
        elif user.role == User.Role.BUYER:
            return queryset.filter(buyer=user)
        elif user.role == User.Role.ADMIN:
            return queryset
        else:
            return queryset.none()

    def update(self, request, *args, **kwargs):
        """
        Update order status with validation and notifications.
        """
        try:
            order = self.get_object()
            serializer = self.get_serializer(data=request.data, context={'order': order})
            serializer.is_valid(raise_exception=True)

            new_status = serializer.validated_data['new_status']
            notes = serializer.validated_data.get('notes', '')

            # Validate user can update to this status
            user = request.user
            if user.role == User.Role.FARMER:
                # Farmers can only update to certain statuses
                valid_farmer_statuses = [
                    Order.Status.CONFIRMED,
                    Order.Status.PROCESSING,
                    Order.Status.SHIPPED,
                    Order.Status.CANCELLED
                ]
                if new_status not in valid_farmer_statuses:
                    raise AuthorizationException("Farmers cannot update to this status")
            elif user.role == User.Role.BUYER:
                # Buyers can only cancel orders
                if new_status != Order.Status.CANCELLED:
                    raise AuthorizationException("Buyers can only cancel orders")

            # Update order status
            old_status = order.status
            order.status = new_status

            # Set timestamps based on status
            if new_status == Order.Status.CONFIRMED:
                order.confirmed_at = timezone.now()
            elif new_status == Order.Status.SHIPPED:
                order.shipped_at = timezone.now()
            elif new_status == Order.Status.DELIVERED:
                order.delivered_at = timezone.now()
            elif new_status == Order.Status.CANCELLED:
                order.cancelled_at = timezone.now()
                # Restore listing quantity if order is cancelled
                if order.listing:
                    order.listing.quantity_available += order.quantity_ordered
                    order.listing.save(update_fields=['quantity_available'])

            # Add notes
            if notes:
                if user.role == User.Role.FARMER:
                    order.seller_notes = notes
                else:
                    order.buyer_notes = notes

            order.save()

            # Create tracking update if status indicates shipping
            if new_status in [Order.Status.SHIPPED, Order.Status.DELIVERED]:
                OrderTracking.objects.create(
                    order=order,
                    status=new_status,
                    notes=notes,
                    tracking_number=serializer.validated_data.get('tracking_number', ''),
                    carrier_name=serializer.validated_data.get('carrier_name', ''),
                    location_description=f"Order {new_status.lower()}",
                )

            # Create activity log
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=user,
                activity_type='ORDER_UPDATE',
                request=request,
                description=f"Updated order {order.order_number} from {old_status} to {new_status}",
                metadata={
                    'order_id': str(order.id),
                    'old_status': old_status,
                    'new_status': new_status,
                }
            )

            # Send notification to the other party
            from apps.notifications.models import Notification
            recipient = order.buyer if user == order.seller else order.seller
            Notification.objects.create(
                recipient=recipient,
                sender=user,
                title=f"Order {order.order_number} updated",
                message=f"Order status changed to {new_status}.",
                notification_type=Notification.Type.ORDER_UPDATE,
                related_object_type=Notification.RelatedObjectType.ORDER,
                related_object_id=order.id,
                action_url=f"/orders/{order.id}/",
            )

            return Response({
                'success': True,
                'data': OrderDetailSerializer(order).data,
                'message': f'Order status updated to {new_status}',
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


class OrderPaymentView(generics.CreateAPIView):
    """
    Process order payments.
    """
    serializer_class = OrderPaymentSerializer
    permission_classes = [permissions.IsAuthenticated, IsBuyer, IsActiveUser]

    def get_queryset(self):
        """
        Get orders that user can pay for.
        """
        return Order.objects.filter(buyer=self.request.user)

    def create(self, request, *args, **kwargs):
        """
        Process payment for an order.
        """
        try:
            order_id = kwargs.get('order_id')
            order = get_object_or_404(Order, id=order_id, buyer=request.user)

            # Check if order can be paid for
            if order.payment_status == Order.PaymentStatus.PAID:
                return Response({
                    'success': False,
                    'error': {
                        'code': 'ALREADY_PAID',
                        'message': 'This order has already been paid for.',
                    },
                    'timestamp': timezone.now().isoformat(),
                }, status=status.HTTP_400_BAD_REQUEST)

            if order.status in [Order.Status.CANCELLED, Order.Status.REFUNDED]:
                return Response({
                    'success': False,
                    'error': {
                        'code': 'INVALID_ORDER_STATUS',
                        'message': 'Cannot pay for this order due to its current status.',
                    },
                    'timestamp': timezone.now().isoformat(),
                }, status=status.HTTP_400_BAD_REQUEST)

            # Create payment
            serializer = self.get_serializer(data=request.data, context={'order': order})
            serializer.is_valid(raise_exception=True)
            payment = serializer.save()

            # Update order payment status
            order.payment_status = Order.PaymentStatus.PAID
            order.save(update_fields=['payment_status'])

            # Create activity log
            from apps.dashboard.models import UserActivity
            UserActivity.objects.create(
                user=request.user,
                activity_type='PAYMENT',
                request=request,
                description=f"Payment processed for order {order.order_number}",
                metadata={
                    'order_id': str(order.id),
                    'payment_id': str(payment.id),
                    'amount': float(payment.amount),
                }
            )

            # Send notification to seller
            from apps.notifications.models import Notification
            Notification.objects.create(
                recipient=order.seller,
                sender=request.user,
                title=f"Payment received for order {order.order_number}",
                message=f"Payment of {payment.amount} {payment.currency} has been received.",
                notification_type=Notification.Type.PAYMENT,
                related_object_type=Notification.RelatedObjectType.PAYMENT,
                related_object_id=payment.id,
                action_url=f"/orders/{order.id}/",
            )

            return Response({
                'success': True,
                'data': {
                    'payment_id': str(payment.id),
                    'amount': str(payment.amount),
                    'status': payment.status,
                },
                'message': 'Payment processed successfully',
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


class OrderListView(generics.ListAPIView):
    """
    List orders with advanced filtering (for both buyers and sellers).
    """
    serializer_class = OrderSerializer
    pagination_class = StandardResultsSetPagination
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]

    def get_queryset(self):
        """
        Get filtered orders based on user role and parameters.
        """
        user = self.request.user
        queryset = Order.objects.select_related('buyer', 'seller', 'listing')

        # Filter based on user role
        if user.role == User.Role.BUYER:
            queryset = queryset.filter(buyer=user)
        elif user.role == User.Role.FARMER:
            queryset = queryset.filter(seller=user)
        elif user.role == User.Role.ADMIN:
            # Admin can see all orders
            pass
        else:
            return queryset.none()

        # Apply search filters
        search_serializer = OrderSearchSerializer(data=self.request.query_params)
        if search_serializer.is_valid():
            search_params = search_serializer.validated_data

            if search_params.get('status'):
                queryset = queryset.filter(status=search_params['status'])

            if search_params.get('payment_status'):
                queryset = queryset.filter(payment_status=search_params['payment_status'])

            if search_params.get('payment_method'):
                queryset = queryset.filter(payment_method=search_params['payment_method'])

            if search_params.get('start_date'):
                queryset = queryset.filter(created_at__date__gte=search_params['start_date'])

            if search_params.get('end_date'):
                queryset = queryset.filter(created_at__date__lte=search_params['end_date'])

            if search_params.get('min_amount'):
                queryset = queryset.filter(final_amount__gte=search_params['min_amount'])

            if search_params.get('max_amount'):
                queryset = queryset.filter(final_amount__lte=search_params['max_amount'])

            # Apply sorting
            sort_by = search_params.get('sort_by', 'newest')
            if sort_by == 'newest':
                queryset = queryset.order_by('-created_at')
            elif sort_by == 'oldest':
                queryset = queryset.order_by('created_at')
            elif sort_by == 'amount_high':
                queryset = queryset.order_by('-final_amount')
            elif sort_by == 'amount_low':
                queryset = queryset.order_by('final_amount')
            elif sort_by == 'status':
                queryset = queryset.order_by('status', '-created_at')

        return queryset


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsActiveUser])
def order_statistics(request):
    """
    Get order statistics for the current user.
    """
    try:
        user = request.user
        stats = {}

        if user.role == User.Role.BUYER:
            # Buyer statistics
            orders = Order.objects.filter(buyer=user)
            stats['buyer'] = {
                'total_orders': orders.count(),
                'pending_orders': orders.filter(status=Order.Status.PENDING).count(),
                'confirmed_orders': orders.filter(status=Order.Status.CONFIRMED).count(),
                'delivered_orders': orders.filter(status=Order.Status.DELIVERED).count(),
                'cancelled_orders': orders.filter(status=Order.Status.CANCELLED).count(),
                'total_spent': orders.aggregate(
                    total=Sum('final_amount')
                )['total'] or 0,
                'average_order_value': orders.aggregate(
                    avg=Avg('final_amount')
                )['avg'] or 0,
            }

        elif user.role == User.Role.FARMER:
            # Farmer statistics
            orders = Order.objects.filter(seller=user)
            stats['farmer'] = {
                'total_orders': orders.count(),
                'pending_orders': orders.filter(status=Order.Status.PENDING).count(),
                'confirmed_orders': orders.filter(status=Order.Status.CONFIRMED).count(),
                'shipped_orders': orders.filter(status=Order.Status.SHIPPED).count(),
                'delivered_orders': orders.filter(status=Order.Status.DELIVERED).count(),
                'total_revenue': orders.aggregate(
                    total=Sum('final_amount')
                )['total'] or 0,
                'average_order_value': orders.aggregate(
                    avg=Avg('final_amount')
                )['avg'] or 0,
                'total_products_sold': orders.aggregate(
                    total=Sum('quantity_ordered')
                )['total'] or 0,
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
                'message': 'Failed to retrieve order statistics.',
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsActiveUser])
def create_order_review(request, order_id):
    """
    Create a review for a completed order.
    """
    try:
        order = get_object_or_404(Order, id=order_id)

        # Create serializer with order context
        serializer = OrderReviewSerializer(
            data=request.data,
            context={'order': order, 'request': request}
        )
        serializer.is_valid(raise_exception=True)
        review = serializer.save()

        # Update seller rating
        seller_reviews = OrderReview.objects.filter(order__seller=order.seller)
        if seller_reviews.exists():
            avg_rating = seller_reviews.aggregate(avg=Avg('overall_rating'))['avg']
            # Update seller's average rating (this would be implemented in the user profile model)

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
@permission_classes([permissions.IsAuthenticated, IsActiveUser])
def order_tracking(request, order_id):
    """
    Get tracking information for an order.
    """
    try:
        order = get_object_or_404(Order, id=order_id)

        # Check if user can access this order
        if request.user not in [order.buyer, order.seller] and request.user.role != User.Role.ADMIN:
            raise PermissionError("You don't have permission to view this order")

        tracking_updates = order.tracking_updates.all().order_by('-created_at')

        tracking_data = [
            {
                'id': str(t.id),
                'status': t.status,
                'location_description': t.location_description,
                'notes': t.notes,
                'tracking_number': t.tracking_number,
                'carrier_name': t.carrier_name,
                'created_at': format_date(t.created_at, '%B %d, %Y at %I:%M %p'),
            }
            for t in tracking_updates
        ]

        return Response({
            'success': True,
            'data': {
                'order_id': str(order.id),
                'order_number': order.order_number,
                'current_status': order.status,
                'tracking_updates': tracking_data,
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'success': False,
            'error': {
                'code': 'TRACKING_ERROR',
                'message': 'Failed to retrieve tracking information.',
            },
            'timestamp': timezone.now().isoformat(),
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)