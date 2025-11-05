"""
Supplier management URLs for AgriLink API.
"""
from django.urls import path
from .views import (
    SupplierProductListCreateView,
    SupplierProductDetailView,
    SupplierInquiryListView,
    SupplierListView,
)

urlpatterns = [
    # Supplier Directory
    path('', SupplierListView.as_view(), name='supplier_list'),

    # Products
    path('products/', SupplierProductListCreateView.as_view(), name='supplier_products'),
    path('products/<uuid:product_id>/', SupplierProductDetailView.as_view(), name='supplier_product_detail'),

    # Inquiries
    path('inquiries/', SupplierInquiryListView.as_view(), name='supplier_inquiries'),
]