"""
Expert services URLs for AgriLink API.
"""
from django.urls import path
from .views import (
    AdvicePostListCreateView,
    AdvicePostDetailView,
    ConsultationListCreateView,
    ConsultationDetailView,
    ConsultationStatusUpdateView,
    ExpertListView,
)

urlpatterns = [
    # Expert Directory
    path('', ExpertListView.as_view(), name='expert_list'),

    # Advice Posts
    path('advice/', AdvicePostListCreateView.as_view(), name='advice_posts'),
    path('advice/<uuid:post_id>/', AdvicePostDetailView.as_view(), name='advice_post_detail'),

    # Consultations
    path('consultations/', ConsultationListCreateView.as_view(), name='consultations'),
    path('consultations/<uuid:consultation_id>/', ConsultationDetailView.as_view(), name='consultation_detail'),
    path('consultations/<uuid:consultation_id>/status/', ConsultationStatusUpdateView.as_view(), name='consultation_status_update'),
]