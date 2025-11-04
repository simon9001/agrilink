"""
Order management URLs for AgriLink API.
"""
from django.urls import path
from .views import (
    OrderListCreateView,
    OrderDetailView,
    OrderStatusUpdateView,
    OrderPaymentView,
    OrderListView,
)

urlpatterns = [
    # Order Management
    path('', OrderListView.as_view(), name='order_list'),
    path('create/', OrderListCreateView.as_view(), name='order_create'),
    path('<uuid:order_id>/', OrderDetailView.as_view(), name='order_detail'),
    path('<uuid:order_id>/status/', OrderStatusUpdateView.as_view(), name='order_status_update'),
    path('<uuid:order_id>/payment/', OrderPaymentView.as_view(), name='order_payment'),
]