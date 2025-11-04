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
    create_listing_inquiry,
    my_listings,
    create_listing_review,
    search_listings,
    featured_listings,
)

urlpatterns = [
    # Categories
    path('categories/', CategoryListView.as_view(), name='categories'),

    # Produce Listings
    path('listings/', ProduceListingListCreateView.as_view(), name='produce_listings'),
    path('listings/my/', my_listings, name='my_listings'),
    path('listings/search/', search_listings, name='search_listings'),
    path('listings/featured/', featured_listings, name='featured_listings'),
    path('listings/<uuid:listing_id>/', ProduceListingDetailView.as_view(), name='produce_listing_detail'),
    path('listings/<uuid:listing_id>/update/', ProduceListingUpdateView.as_view(), name='produce_listing_update'),
    path('listings/<uuid:listing_id>/delete/', ProduceListingDeleteView.as_view(), name='produce_listing_delete'),
    path('listings/<uuid:listing_id>/inquire/', create_listing_inquiry, name='create_listing_inquiry'),
    path('listings/<uuid:listing_id>/review/', create_listing_review, name='create_listing_review'),
]