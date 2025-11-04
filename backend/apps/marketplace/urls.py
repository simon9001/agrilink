"""
Marketplace URLs for AgriLink API.
"""
from django.urls import path
from .views import (
    ProduceListingListCreateView,
    ProduceListingDetailView,
    ProduceListingUpdateView,
    ProduceListingDeleteView,
    CategoryListView,
)

urlpatterns = [
    # Produce Listings
    path('listings/', ProduceListingListCreateView.as_view(), name='produce_listings'),
    path('listings/<uuid:listing_id>/', ProduceListingDetailView.as_view(), name='produce_listing_detail'),
    path('listings/<uuid:listing_id>/update/', ProduceListingUpdateView.as_view(), name='produce_listing_update'),
    path('listings/<uuid:listing_id>/delete/', ProduceListingDeleteView.as_view(), name='produce_listing_delete'),

    # Categories
    path('categories/', CategoryListView.as_view(), name='categories'),
]