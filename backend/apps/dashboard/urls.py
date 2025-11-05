"""
Dashboard URLs for AgriLink API.
"""
from django.urls import path
from .views import (
    FarmerDashboardView,
    BuyerDashboardView,
    SupplierDashboardView,
    ExpertDashboardView,
    AdminDashboardView,
)

urlpatterns = [
    # Role-based Dashboards
    path('farmer/', FarmerDashboardView.as_view(), name='farmer_dashboard'),
    path('buyer/', BuyerDashboardView.as_view(), name='buyer_dashboard'),
    path('supplier/', SupplierDashboardView.as_view(), name='supplier_dashboard'),
    path('expert/', ExpertDashboardView.as_view(), name='expert_dashboard'),
    path('admin/', AdminDashboardView.as_view(), name='admin_dashboard'),
]