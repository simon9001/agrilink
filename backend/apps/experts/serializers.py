"""
Expert services serializers for AgriLink API.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils import timezone
from core.utils import format_currency, format_date
from core.exceptions import ValidationException, NotFoundException
from .models import AdvicePost, AdvicePostLike, AdvicePostComment, Consultation, ConsultationReview

User = get_user_model()


class AdvicePostSerializer(serializers.ModelSerializer):
    """
    Serializer for expert advice posts.
    """
    expert_name = serializers.CharField(source='expert.full_name', read_only=True)
    expert_profile = serializers.SerializerMethodField()
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    formatted_date = serializers.SerializerMethodField()
    reading_time = serializers.ReadOnlyField()
    likes_count = serializers.ReadOnlyField()
    comments_count = serializers.ReadOnlyField()
    is_liked = serializers.SerializerMethodField()

    class Meta:
        model = AdvicePost
        fields = [
            'id', 'expert', 'expert_name', 'expert_profile',
            'title', 'slug', 'excerpt', 'content',
            'category', 'category_display',
            'target_audience', 'featured_image', 'video_url',
            'meta_title', 'meta_description', 'tags',
            'is_featured', 'view_count', 'likes_count',
            'comments_count', 'is_liked',
            'formatted_date', 'reading_time',
            'published_at', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'expert', 'expert_name', 'slug', 'view_count',
            'likes_count', 'comments_count', 'published_at',
            'created_at', 'updated_at'
        ]

    def get_expert_profile(self, obj):
        """
        Get expert profile information.
        """
        if hasattr(obj.expert, 'expert_profile'):
            profile = obj.expert.expert_profile
            return {
                'specialization': profile.specialization,
                'years_experience': profile.years_experience,
                'rating': profile.rating,
                'is_verified_expert': profile.is_verified_expert,
                'consultation_rate': profile.consultation_rate,
            }
        return None

    def get_formatted_date(self, obj):
        """
        Get formatted published date.
        """
        date = obj.published_at or obj.created_at
        return format_date(date, '%B %d, %Y')

    def get_is_liked(self, obj):
        """
        Check if current user has liked this post.
        """
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(user=request.user).exists()
        return False

    def validate_title(self, value):
        """
        Validate post title.
        """
        if len(value.strip()) < 10:
            raise serializers.ValidationError("Title must be at least 10 characters long")
        if len(value) > 200:
            raise serializers.ValidationError("Title cannot exceed 200 characters")
        return value.strip()

    def validate_content(self, value):
        """
        Validate post content.
        """
        if len(value.strip()) < 100:
            raise serializers.ValidationError("Content must be at least 100 characters long")
        return value.strip()

    def validate_excerpt(self, value):
        """
        Validate post excerpt.
        """
        if value and len(value) > 500:
            raise serializers.ValidationError("Excerpt cannot exceed 500 characters")
        return value

    def validate_target_audience(self, value):
        """
        Validate target audience.
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Target audience must be a list")
        valid_audiences = [choice[0] for choice in AdvicePost.TargetAudience.choices]
        for audience in value:
            if audience not in valid_audiences:
                raise serializers.ValidationError(f"Invalid target audience: {audience}")
        return value

    def validate_tags(self, value):
        """
        Validate tags.
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Tags must be a list")
        if len(value) > 10:
            raise serializers.ValidationError("Maximum 10 tags allowed")
        # Remove duplicates and empty tags
        return list(set(tag.strip() for tag in value if tag.strip()))

    def validate_images(self, value):
        """
        Validate images list.
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Images must be a list")
        if len(value) > 10:
            raise serializers.ValidationError("Maximum 10 images allowed")
        return value

    def create(self, validated_data):
        """
        Create advice post with automatic slug generation.
        """
        # Create post
        post = AdvicePost.objects.create(**validated_data)

        # Generate slug if not provided
        if not post.slug:
            from django.utils.text import slugify
            base_slug = slugify(post.title)
            unique_slug = base_slug
            counter = 1
            while AdvicePost.objects.filter(slug=unique_slug).exists():
                unique_slug = f"{base_slug}-{counter}"
                counter += 1
            post.slug = unique_slug
            post.save()

        return post


class AdvicePostDetailSerializer(AdvicePostSerializer):
    """
    Detailed serializer for advice posts with related content.
    """
    related_posts = serializers.SerializerMethodField()
    recent_comments = serializers.SerializerMethodField()

    class Meta(AdvicePostSerializer.Meta):
        fields = AdvicePostSerializer.Meta.fields + [
            'related_posts', 'recent_comments'
        ]

    def get_related_posts(self, obj):
        """
        Get related posts from same expert or category.
        """
        related = AdvicePost.objects.filter(
            Q(expert=obj.expert) | Q(category=obj.category)
        ).exclude(id=obj.id).filter(
            is_published=True
        ).distinct()[:3]

        return AdvicePostSerializer(related, many=True, context=self.context).data

    def get_recent_comments(self, obj):
        """
        Get recent comments for the post.
        """
        comments = obj.comments.filter(
            is_approved=True,
            parent=None
        ).order_by('-created_at')[:5]

        return AdvicePostCommentSerializer(
            comments,
            many=True,
            context=self.context
        ).data


class AdvicePostLikeSerializer(serializers.ModelSerializer):
    """
    Serializer for advice post likes.
    """
    class Meta:
        model = AdvicePostLike
        fields = ['post', 'user', 'created_at']
        read_only_fields = ['user', 'created_at']

    def validate(self, attrs):
        """
        Validate like constraints.
        """
        post = attrs['post']
        user = self.context['request'].user

        # Check if user already liked this post
        if AdvicePostLike.objects.filter(post=post, user=user).exists():
            raise serializers.ValidationError("You have already liked this post")

        # Check if user can like their own post
        if post.expert == user:
            raise serializers.ValidationError("You cannot like your own post")

        return attrs


class AdvicePostCommentSerializer(serializers.ModelSerializer):
    """
    Serializer for advice post comments.
    """
    author_name = serializers.CharField(source='user.full_name', read_only=True)
    formatted_date = serializers.SerializerMethodField()
    replies = serializers.SerializerMethodField()
    is_author = serializers.SerializerMethodField()

    class Meta:
        model = AdvicePostComment
        fields = [
            'id', 'post', 'user', 'author_name', 'parent',
            'content', 'is_edited', 'is_approved',
            'formatted_date', 'is_author', 'replies'
        ]
        read_only_fields = [
            'id', 'user', 'author_name', 'is_edited',
            'is_approved', 'formatted_date', 'is_author'
        ]

    def get_formatted_date(self, obj):
        """
        Get formatted comment date.
        """
        return format_date(obj.created_at, '%B %d, %Y at %I:%M %p')

    def get_replies(self, obj):
        """
        Get replies to this comment.
        """
        replies = obj.replies.filter(is_approved=True).order_by('created_at')
        return AdvicePostCommentSerializer(
            replies,
            many=True,
            context=self.context
        ).data

    def get_is_author(self, obj):
        """
        Check if current user is the comment author.
        """
        request = self.context.get('request')
        return request and request.user == obj.user

    def validate_content(self, value):
        """
        Validate comment content.
        """
        if len(value.strip()) < 3:
            raise serializers.ValidationError("Comment must be at least 3 characters long")
        if len(value) > 1000:
            raise serializers.ValidationError("Comment cannot exceed 1000 characters")
        return value.strip()

    def validate(self, attrs):
        """
        Validate comment constraints.
        """
        post = attrs['post']
        parent = attrs.get('parent')

        # Check if parent comment belongs to the same post
        if parent and parent.post != post:
            raise serializers.ValidationError("Parent comment must belong to the same post")

        return attrs


class ConsultationSerializer(serializers.ModelSerializer):
    """
    Serializer for consultations.
    """
    expert_name = serializers.CharField(source='expert.full_name', read_only=True)
    farmer_name = serializers.CharField(source='farmer.full_name', read_only=True)
    expert_profile = serializers.SerializerMethodField()
    farmer_profile = serializers.SerializerMethodField()

    consultation_type_display = serializers.CharField(source='get_consultation_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)

    formatted_rate = serializers.SerializerMethodField()
    formatted_total_amount = serializers.SerializerMethodField()
    formatted_scheduled_date = serializers.SerializerMethodField()
    duration_display = serializers.SerializerMethodField()

    class Meta:
        model = Consultation
        fields = [
            'id', 'expert', 'expert_name', 'expert_profile',
            'farmer', 'farmer_name', 'farmer_profile',
            'topic', 'description', 'consultation_type',
            'consultation_type_display', 'scheduled_date',
            'formatted_scheduled_date', 'duration_minutes',
            'duration_display', 'timezone',
            'meeting_url', 'meeting_address', 'meeting_phone',
            'status', 'status_display', 'payment_status',
            'payment_status_display', 'consultation_rate',
            'formatted_rate', 'total_amount',
            'formatted_total_amount', 'currency',
            'actual_start_time', 'actual_end_time',
            'actual_duration_minutes', 'expert_notes',
            'farmer_notes', 'shared_notes',
            'recommendations', 'follow_up_required',
            'follow_up_date', 'follow_up_notes',
            'created_at', 'updated_at',
            'completed_at', 'cancelled_at'
        ]
        read_only_fields = [
            'id', 'expert', 'expert_name', 'farmer', 'farmer_name',
            'actual_start_time', 'actual_end_time',
            'actual_duration_minutes', 'created_at', 'updated_at',
            'completed_at', 'cancelled_at'
        ]

    def get_expert_profile(self, obj):
        """
        Get expert profile information.
        """
        if hasattr(obj.expert, 'expert_profile'):
            profile = obj.expert.expert_profile
            return {
                'specialization': profile.specialization,
                'years_experience': profile.years_experience,
                'rating': profile.rating,
                'consultation_rate': profile.consultation_rate,
            }
        return None

    def get_farmer_profile(self, obj):
        """
        Get farmer profile information.
        """
        if hasattr(obj.farmer, 'farmer_profile'):
            profile = obj.farmer.farmer_profile
            return {
                'farm_name': profile.farm_name,
                'farm_size': profile.farm_size,
                'primary_crops': profile.primary_crops,
            }
        return None

    def get_formatted_rate(self, obj):
        """
        Format consultation rate.
        """
        return format_currency(obj.consultation_rate)

    def get_formatted_total_amount(self, obj):
        """
        Format total amount.
        """
        if obj.total_amount:
            return format_currency(obj.total_amount)
        return None

    def get_formatted_scheduled_date(self, obj):
        """
        Get formatted scheduled date.
        """
        return format_date(obj.scheduled_date, '%B %d, %Y at %I:%M %p')

    def get_duration_display(self, obj):
        """
        Get human-readable duration display.
        """
        hours = obj.duration_minutes // 60
        minutes = obj.duration_minutes % 60

        if hours == 0:
            return f"{minutes} minutes"
        elif minutes == 0:
            return f"{hours} hour{'s' if hours > 1 else ''}"
        else:
            return f"{hours} hour{'s' if hours > 1 else ''} {minutes} minutes"

    def validate_topic(self, value):
        """
        Validate consultation topic.
        """
        if len(value.strip()) < 5:
            raise serializers.ValidationError("Topic must be at least 5 characters long")
        if len(value) > 200:
            raise serializers.ValidationError("Topic cannot exceed 200 characters")
        return value.strip()

    def validate_description(self, value):
        """
        Validate consultation description.
        """
        if len(value.strip()) < 20:
            raise serializers.ValidationError("Description must be at least 20 characters long")
        return value.strip()

    def validate_scheduled_date(self, value):
        """
        Validate scheduled date.
        """
        if value < timezone.now():
            raise serializers.ValidationError("Scheduled date cannot be in the past")

        # Check if date is too far in future (e.g., more than 6 months)
        six_months_from_now = timezone.now() + timezone.timedelta(days=180)
        if value > six_months_from_now:
            raise serializers.ValidationError("Scheduled date cannot be more than 6 months in the future")

        return value

    def validate_duration_minutes(self, value):
        """
        Validate consultation duration.
        """
        if value < 15:
            raise serializers.ValidationError("Duration must be at least 15 minutes")
        if value > 480:  # 8 hours
            raise serializers.ValidationError("Duration cannot exceed 8 hours")
        return value

    def validate(self, attrs):
        """
        Validate consultation constraints.
        """
        expert = attrs.get('expert')
        farmer = self.context['request'].user

        # Check if user is trying to book themselves
        if expert == farmer:
            raise serializers.ValidationError("You cannot book a consultation with yourself")

        # Check if user role is farmer
        if farmer.role != User.Role.FARMER:
            raise serializers.ValidationError("Only farmers can book consultations")

        return attrs

    def create(self, validated_data):
        """
        Create consultation with automatic calculations.
        """
        farmer = self.context['request'].user
        expert = validated_data['expert']
        duration = validated_data['duration_minutes']

        # Set farmer
        validated_data['farmer'] = farmer

        # Get consultation rate from expert profile
        try:
            expert_profile = expert.expert_profile
            consultation_rate = expert_profile.consultation_rate
        except:
            raise ValidationException("Expert profile not found or missing consultation rate")

        # Set consultation rate and calculate total amount
        validated_data['consultation_rate'] = consultation_rate
        hours = duration / 60
        validated_data['total_amount'] = consultation_rate * hours

        # Create consultation
        consultation = Consultation.objects.create(**validated_data)

        # Create activity log
        from apps.dashboard.models import UserActivity
        UserActivity.objects.create(
            user=farmer,
            activity_type='CONSULTATION_BOOK',
            description=f"Booked consultation with {expert.full_name}: {consultation.topic}",
            metadata={
                'consultation_id': str(consultation.id),
                'expert_id': str(expert.id),
                'amount': float(consultation.total_amount),
            }
        )

        # Send notification to expert
        from apps.notifications.models import Notification
        Notification.objects.create(
            recipient=expert,
            sender=farmer,
            title=f"New consultation request: {consultation.topic}",
            message=f"{farmer.full_name} has requested a consultation.",
            notification_type=Notification.Type.CONSULTATION,
            related_object_type=Notification.RelatedObjectType.CONSULTATION,
            related_object_id=consultation.id,
            action_url=f"/experts/consultations/{consultation.id}/",
        )

        return consultation


class ConsultationStatusUpdateSerializer(serializers.Serializer):
    """
    Serializer for updating consultation status.
    """
    new_status = serializers.ChoiceField(choices=Consultation.Status.choices)
    notes = serializers.CharField(required=False, allow_blank=True)
    payment_amount = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)

    def validate(self, attrs):
        """
        Validate status transition.
        """
        new_status = attrs['new_status']
        consultation = self.context['consultation']
        user = self.context['request'].user

        # Validate status transitions based on user role
        if user == consultation.expert:
            # Expert can update to these statuses
            valid_expert_statuses = [
                Consultation.Status.SCHEDULED,
                Consultation.Status.IN_PROGRESS,
                Consultation.Status.COMPLETED,
                Consultation.Status.CANCELLED
            ]
            if new_status not in valid_expert_statuses:
                raise serializers.ValidationError(f"Experts cannot update to {new_status}")

            # Require notes for cancellation
            if new_status == Consultation.Status.CANCELLED and not attrs.get('notes'):
                raise serializers.ValidationError("Notes are required when cancelling a consultation")

        elif user == consultation.farmer:
            # Farmers can only cancel consultations
            if new_status != Consultation.Status.CANCELLED:
                raise serializers.ValidationError("Farmers can only cancel consultations")

        return attrs


class ConsultationReviewSerializer(serializers.ModelSerializer):
    """
    Serializer for consultation reviews.
    """
    reviewer_name = serializers.CharField(source='reviewer.full_name', read_only=True)
    formatted_date = serializers.SerializerMethodField()

    class Meta:
        model = ConsultationReview
        fields = [
            'id', 'consultation', 'reviewer', 'reviewer_name',
            'overall_rating', 'expertise_rating',
            'communication_rating', 'helpfulness_rating',
            'title', 'comment', 'would_recommend',
            'would_consult_again', 'is_public', 'is_verified',
            'formatted_date', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'reviewer', 'reviewer_name', 'consultation',
            'is_verified', 'created_at', 'updated_at'
        ]

    def get_formatted_date(self, obj):
        """
        Get formatted review date.
        """
        return format_date(obj.created_at, '%B %d, %Y')

    def validate_overall_rating(self, value):
        """
        Validate overall rating.
        """
        if not 1 <= value <= 5:
            raise serializers.ValidationError("Overall rating must be between 1 and 5")
        return value

    def validate(self, attrs):
        """
        Validate review constraints.
        """
        consultation = self.context['consultation']
        reviewer = self.context['request'].user

        # Check if user can review this consultation
        if consultation.farmer != reviewer:
            raise serializers.ValidationError("Only farmers can review consultations")

        # Check if consultation is completed
        if consultation.status != Consultation.Status.COMPLETED:
            raise serializers.ValidationError("You can only review completed consultations")

        # Check if user has already reviewed this consultation
        if ConsultationReview.objects.filter(consultation=consultation, reviewer=reviewer).exists():
            raise serializers.ValidationError("You have already reviewed this consultation")

        # Validate individual ratings
        ratings = ['expertise_rating', 'communication_rating', 'helpfulness_rating']
        for rating_field in ratings:
            if rating_field in attrs and not 1 <= attrs[rating_field] <= 5:
                raise serializers.ValidationError(f"{rating_field} must be between 1 and 5")

        return attrs


class ExpertListSerializer(serializers.ModelSerializer):
    """
    Serializer for listing experts.
    """
    full_name = serializers.CharField(read_only=True)
    rating_display = serializers.SerializerMethodField()
    consultation_count = serializers.SerializerMethodField()
    specialization_display = serializers.SerializerMethodField()
    profile = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'full_name', 'profile_picture', 'rating_display',
            'consultation_count', 'specialization_display', 'profile'
        ]

    def get_rating_display(self, obj):
        """
        Get formatted rating display.
        """
        if hasattr(obj, 'expert_profile'):
            profile = obj.expert_profile
            if profile.rating > 0:
                return f"{profile.rating:.1f}/5.0 ({profile.total_consultations} consultations)"
            return "No ratings yet"
        return "No expert profile"

    def get_consultation_count(self, obj):
        """
        Get total consultation count.
        """
        return Consultation.objects.filter(expert=obj).count()

    def get_specialization_display(self, obj):
        """
        Get specialization display.
        """
        if hasattr(obj, 'expert_profile'):
            return obj.expert_profile.specialization
        return []

    def get_profile(self, obj):
        """
        Get expert profile details.
        """
        if hasattr(obj, 'expert_profile'):
            profile = obj.expert_profile
            return {
                'years_experience': profile.years_experience,
                'consultation_rate': profile.consultation_rate,
                'is_verified_expert': profile.is_verified_expert,
                'bio': profile.bio,
            }
        return None