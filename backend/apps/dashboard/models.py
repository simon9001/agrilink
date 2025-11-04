"""
Dashboard analytics models for AgriLink.
"""
import uuid
from django.contrib.gis.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db.models import Sum, Count, Avg

User = get_user_model()


class UserActivity(models.Model):
    """
    Track user activities for analytics.
    """
    class ActivityType(models.TextChoices):
        LOGIN = 'LOGIN', 'Login'
        LOGOUT = 'LOGOUT', 'Logout'
        REGISTER = 'REGISTER', 'Register'
        PROFILE_UPDATE = 'PROFILE_UPDATE', 'Profile Update'
        LISTING_CREATE = 'LISTING_CREATE', 'Listing Created'
        LISTING_VIEW = 'LISTING_VIEW', 'Listing View'
        ORDER_PLACE = 'ORDER_PLACE', 'Order Placed'
        ORDER_COMPLETE = 'ORDER_COMPLETE', 'Order Completed'
        CONSULTATION_BOOK = 'CONSULTATION_BOOK', 'Consultation Booked'
        INQUIRY_SEND = 'INQUIRY_SEND', 'Inquiry Sent'
        MESSAGE_SEND = 'MESSAGE_SEND', 'Message Sent'
        SEARCH = 'SEARCH', 'Search'

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='activities')
    activity_type = models.CharField(max_length=30, choices=ActivityType.choices, db_index=True)
    description = models.TextField(blank=True)

    # Request information
    ip_address = models.GenericIPAddressField(blank=True, null=True)
    user_agent = models.TextField(blank=True)
    request_path = models.CharField(max_length=500, blank=True)
    request_method = models.CharField(max_length=10, blank=True)

    # Location information
    country = models.CharField(max_length=2, blank=True, help_text="ISO 3166-1 alpha-2")
    city = models.CharField(max_length=100, blank=True)
    location = models.PointField(geography=True, blank=True, null=True)

    # Device information
    device_type = models.CharField(
        max_length=20,
        choices=[
            ('DESKTOP', 'Desktop'),
            ('MOBILE', 'Mobile'),
            ('TABLET', 'Tablet'),
        ],
        blank=True
    )
    browser = models.CharField(max_length=100, blank=True)
    operating_system = models.CharField(max_length=100, blank=True)

    # Additional metadata
    metadata = models.JSONField(default=dict, help_text="Additional activity data")

    # Timestamps
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'user_activities'
        indexes = [
            models.Index(fields=['user', 'activity_type']),
            models.Index(fields=['activity_type', 'timestamp']),
            models.Index(fields=['timestamp']),
            models.Index(fields=['ip_address']),
        ]
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.user.full_name} - {self.activity_type} at {self.timestamp}"


class SystemMetric(models.Model):
    """
    Track system-level metrics for admin dashboard.
    """
    class MetricType(models.TextChoices):
        USER_COUNT = 'USER_COUNT', 'User Count'
        ACTIVE_USERS = 'ACTIVE_USERS', 'Active Users'
        LISTING_COUNT = 'LISTING_COUNT', 'Listing Count'
        ORDER_COUNT = 'ORDER_COUNT', 'Order Count'
        ORDER_VALUE = 'ORDER_VALUE', 'Order Value'
        CONSULTATION_COUNT = 'CONSULTATION_COUNT', 'Consultation Count'
        INQUIRY_COUNT = 'INQUIRY_COUNT', 'Inquiry Count'
        REVENUE = 'REVENUE', 'Revenue'
        PAGE_VIEWS = 'PAGE_VIEWS', 'Page Views'
        API_CALLS = 'API_CALLS', 'API Calls'
        ERROR_RATE = 'ERROR_RATE', 'Error Rate'
        RESPONSE_TIME = 'RESPONSE_TIME', 'Response Time'

    metric_type = models.CharField(max_length=30, choices=MetricType.choices, db_index=True)
    value = models.DecimalField(max_digits=20, decimal_places=4)
    unit = models.CharField(max_length=20, default='count')

    # Time period
    date = models.DateField(db_index=True)
    hour = models.IntegerField(blank=True, null=True, help_text="Hour of the day (0-23)")

    # Dimensions for filtering
    user_role = models.CharField(
        max_length=20,
        choices=User.Role.choices,
        blank=True,
        null=True
    )
    category = models.CharField(max_length=100, blank=True)
    region = models.CharField(max_length=100, blank=True)

    # Additional data
    metadata = models.JSONField(default=dict)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'system_metrics'
        indexes = [
            models.Index(fields=['metric_type', 'date']),
            models.Index(fields=['date']),
            models.Index(fields=['user_role']),
        ]
        unique_together = ['metric_type', 'date', 'hour', 'user_role', 'category', 'region']
        ordering = ['-date', '-hour']

    def __str__(self):
        return f"{self.metric_type}: {self.value} {self.unit} on {self.date}"


class MarketInsight(models.Model):
    """
    Market insights and trends for dashboard.
    """
    class InsightType(models.TextChoices):
        PRICE_TREND = 'PRICE_TREND', 'Price Trend'
        DEMAND_SURGE = 'DEMAND_SURGE', 'Demand Surge'
        SUPPLY_SHORTAGE = 'SUPPLY_SHORTAGE', 'Supply Shortage'
        SEASONAL_PATTERN = 'SEASONAL_PATTERN', 'Seasonal Pattern'
        MARKET_ENTRY = 'MARKET_ENTRY', 'Market Entry'
    class Confidence(models.TextChoices):
        LOW = 'LOW', 'Low'
        MEDIUM = 'MEDIUM', 'Medium'
        HIGH = 'HIGH', 'High'

    title = models.CharField(max_length=200)
    insight_type = models.CharField(max_length=30, choices=InsightType.choices)
    description = models.TextField()

    # Geographic scope
    region = models.CharField(max_length=100, blank=True)
    country = models.CharField(max_length=2, blank=True, help_text="ISO 3166-1 alpha-2")
    location = models.PointField(geography=True, blank=True, null=True)

    # Product/category focus
    product_category = models.CharField(max_length=100, blank=True)
    specific_products = models.JSONField(default=list, help_text="Specific products this insight applies to")

    # Confidence and impact
    confidence_level = models.CharField(max_length=10, choices=Confidence.choices, default=Confidence.MEDIUM)
    impact_level = models.CharField(
        max_length=10,
        choices=[
            ('LOW', 'Low'),
            ('MEDIUM', 'Medium'),
            ('HIGH', 'High'),
            ('CRITICAL', 'Critical'),
        ],
        default='MEDIUM'
    )

    # Timeframe
    effective_from = models.DateField()
    effective_to = models.DateField()

    # Data and sources
    data_points = models.IntegerField(default=0, help_text="Number of data points analyzed")
    sources = models.JSONField(default=list, help_text="Data sources used")

    # Recommendations
    recommendations = models.JSONField(default=list, help_text="Actionable recommendations")

    # Target audience
    target_roles = models.JSONField(default=list, help_text="User roles this insight is relevant for")

    # Status
    is_published = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'market_insights'
        indexes = [
            models.Index(fields=['insight_type', 'is_published']),
            models.Index(fields=['product_category']),
            models.Index(fields=['region']),
            models.Index(fields=['effective_from', 'effective_to']),
            models.Index(fields=['confidence_level']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.insight_type})"


class UserActivitySummary(models.Model):
    """
    Pre-computed user activity summaries for dashboard performance.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='activity_summaries')

    # Time period
    date = models.DateField()
    period_type = models.CharField(
        max_length=10,
        choices=[
            ('DAILY', 'Daily'),
            ('WEEKLY', 'Weekly'),
            ('MONTHLY', 'Monthly'),
        ],
        default='DAILY'
    )

    # Activity counts
    login_count = models.IntegerField(default=0)
    listing_views = models.IntegerField(default=0)
    inquiries_sent = models.IntegerField(default=0)
    orders_placed = models.IntegerField(default=0)
    consultations_booked = models.IntegerField(default=0)

    # Business metrics
    total_order_value = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    total_consultation_value = models.DecimalField(max_digits=15, decimal_places=2, default=0)

    # Engagement metrics
    session_duration_minutes = models.IntegerField(default=0)
    pages_viewed = models.IntegerField(default=0)
    bounce_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'user_activity_summaries'
        indexes = [
            models.Index(fields=['user', 'date']),
            models.Index(fields=['date', 'period_type']),
        ]
        unique_together = ['user', 'date', 'period_type']
        ordering = ['-date']

    def __str__(self):
        return f"Activity summary for {self.user.full_name} on {self.date}"


class SystemAlert(models.Model):
    """
    System alerts for admin dashboard.
    """
    class AlertType(models.TextChoices):
        PERFORMANCE = 'PERFORMANCE', 'Performance Issue'
        SECURITY = 'SECURITY', 'Security Alert'
        ERROR_RATE = 'ERROR_RATE', 'High Error Rate'
        DATABASE = 'DATABASE', 'Database Issue'
        PAYMENT = 'PAYMENT', 'Payment Issue'
        USER_REPORT = 'USER_REPORT', 'User Report'
        SYSTEM_MAINTENANCE = 'SYSTEM_MAINTENANCE', 'Maintenance Required'
    class Severity(models.TextChoices):
        LOW = 'LOW', 'Low'
        MEDIUM = 'MEDIUM', 'Medium'
        HIGH = 'HIGH', 'High'
        CRITICAL = 'CRITICAL', 'Critical'

    title = models.CharField(max_length=200)
    alert_type = models.CharField(max_length=30, choices=AlertType.choices)
    description = models.TextField()

    severity = models.CharField(max_length=10, choices=Severity.choices, default=Severity.MEDIUM)
    is_active = models.BooleanField(default=True)
    is_resolved = models.BooleanField(default=False)

    # Source information
    source_system = models.CharField(max_length=100, help_text="System or component that generated the alert")
    source_id = models.CharField(max_length=100, blank=True, help_text="ID of the source object")

    # Metrics
    threshold_value = models.DecimalField(max_digits=20, decimal_places=4, blank=True, null=True)
    actual_value = models.DecimalField(max_digits=20, decimal_places=4, blank=True, null=True)

    # Resolution
    resolution_notes = models.TextField(blank=True)
    resolved_at = models.DateTimeField(blank=True, null=True)
    resolved_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='resolved_alerts'
    )

    # Notifications
    notifications_sent = models.JSONField(default=list, help_text="List of notification channels used")
    escalation_level = models.IntegerField(default=0, help_text="Current escalation level")

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'system_alerts'
        indexes = [
            models.Index(fields=['alert_type', 'is_active']),
            models.Index(fields=['severity', 'is_active']),
            models.Index(fields=['is_resolved']),
            models.Index(fields=['created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.severity})"

    def escalate(self):
        """
        Escalate the alert to the next level.
        """
        self.escalation_level += 1
        self.save(update_fields=['escalation_level'])

    def resolve(self, resolved_by, notes=""):
        """
        Mark the alert as resolved.
        """
        self.is_resolved = True
        self.resolved_at = timezone.now()
        self.resolved_by = resolved_by
        self.resolution_notes = notes
        self.is_active = False
        self.save()


class Report(models.Model):
    """
    Generated reports for dashboard analytics.
    """
    class ReportType(models.TextChoices):
        USER_ACTIVITY = 'USER_ACTIVITY', 'User Activity Report'
        SALES_PERFORMANCE = 'SALES_PERFORMANCE', 'Sales Performance Report'
        MARKET_ANALYSIS = 'MARKET_ANALYSIS', 'Market Analysis Report'
        FINANCIAL_SUMMARY = 'FINANCIAL_SUMMARY', 'Financial Summary Report'
        SYSTEM_PERFORMANCE = 'SYSTEM_PERFORMANCE', 'System Performance Report'
        COMPLIANCE = 'COMPLIANCE', 'Compliance Report'

    class Status(models.TextChoices):
        GENERATING = 'GENERATING', 'Generating'
        COMPLETED = 'COMPLETED', 'Completed'
        FAILED = 'FAILED', 'Failed'
        SCHEDULED = 'SCHEDULED', 'Scheduled'

    title = models.CharField(max_length=200)
    report_type = models.CharField(max_length=30, choices=ReportType.choices)
    description = models.TextField(blank=True)

    # Date range
    start_date = models.DateField()
    end_date = models.DateField()

    # Filters and parameters
    filters = models.JSONField(default=dict, help_text="Report filters and parameters")
    user_roles = models.JSONField(default=list, help_text="User roles included in report")
    regions = models.JSONField(default=list, help_text="Geographic regions included")

    # File information
    file_url = models.URLField(blank=True, null=True)
    file_format = models.CharField(
        max_length=10,
        choices=[
            ('PDF', 'PDF'),
            ('CSV', 'CSV'),
            ('EXCEL', 'Excel'),
            ('JSON', 'JSON'),
        ],
        default='PDF'
    )
    file_size_bytes = models.BigIntegerField(blank=True, null=True)

    # Status and tracking
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.SCHEDULED)
    progress_percentage = models.IntegerField(default=0)
    error_message = models.TextField(blank=True)

    # Requested by
    requested_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='requested_reports'
    )

    # Generation tracking
    generated_at = models.DateTimeField(blank=True, null=True)
    expires_at = models.DateTimeField(blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'reports'
        indexes = [
            models.Index(fields=['report_type', 'status']),
            models.Index(fields=['requested_by']),
            models.Index(fields=['start_date', 'end_date']),
            models.Index(fields=['created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.report_type})"

    def generate_report(self):
        """
        Set status to generating and start report generation process.
        """
        self.status = self.Status.GENERATING
        self.progress_percentage = 0
        self.save()

    def complete_report(self, file_url, file_size=None):
        """
        Mark report as completed with file information.
        """
        self.status = self.Status.COMPLETED
        self.file_url = file_url
        self.file_size_bytes = file_size
        self.progress_percentage = 100
        self.generated_at = timezone.now()
        self.save()

    def fail_report(self, error_message):
        """
        Mark report generation as failed.
        """
        self.status = self.Status.FAILED
        self.error_message = error_message
        self.save()