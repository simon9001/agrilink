import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/django_api_service.dart';
import '../../core/user_role.dart';
import '../dashboard/widgets/dashboard_stats_widget.dart';
import '../dashboard/widgets/recent_activities_widget.dart';
import '../dashboard/widgets/advice_post_widget.dart';
import '../dashboard/widgets/consultation_list_widget.dart';
import '../dashboard/widgets/quick_actions_widget.dart';

class ExpertDashboard extends StatefulWidget {
  const ExpertDashboard({Key? key}) : super(key: key);

  @override
  State<ExpertDashboard> createState() => _ExpertDashboardState();
}

class _ExpertDashboardState extends State<ExpertDashboard> {
  final DjangoApiService _apiService = DjangoApiService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  // Mock data for development
  final Map<String, dynamic> _mockDashboardData = {
    'stats': {
      'total_posts': 12,
      'total_consultations': 45,
      'completed_consultations': 38,
      'total_earnings': '\$3,750',
      'average_rating': 4.9,
      'active_posts': 8,
      'followers': 234,
      'saved_searches': 12,
      'published_advice': {
        'crop_management': 6,
        'pest_control': 4,
        'irrigigation': 3,
        'soilil_health': 2,
        'livestock': 1,
      },
    },
    'recent_posts': [
      {
        'id': '1',
        'title': 'Integrated Pest Management Strategies',
        'category': 'PEST_CONTROL',
        'excerpt': 'Best practices for integrated pest management in organic farming',
        'content': 'Learn how to manage pests while maintaining organic certification',
        'author': 'Dr. Sarah Johnson',
        'expert_name': 'Dr. Sarah Johnson',
        'author_profile': 'Agricultural Entomologist',
        'expert_profile': {
          'specialization': ['PEST_CONTROL', 'CROP_MANAGEMENT'],
          'years_experience': 15,
          'certifications': ['PhD, Pesticide Applicator'],
          'consultation_rate': 75.00,
          'rating': 4.9,
        },
        'likes_count': 127,
        'comments_count': 23,
        'views': 856,
        'is_liked': false,
        'tags': ['organic', 'pest-control', 'integrated-pest-management'],
        'created_at': '2024-01-15T10:30:00Z',
        'published_at': '2024-01-16T14:30:00Z',
        'reading_time': 5 min read time',
      },
      {
        'id': '2',
        'title': 'Disease Diagnosis Guide',
        'category': 'PEST_CONTROL',
        'excerpt': 'Step-by-step guide for diagnosing common crop diseases',
        'content': 'Identify and treat common plant diseases with visual identification',
        'author': 'Dr. Michael Chen',
        'expert_name': 'Dr. Michael Chen',
        'author_profile': 'Plant Pathologist with 20 years experience',
        'expert_profile': {
          'specialization': ['PEST_CONTROL', 'PATHOLOGY', 'DISEASE_DIAGNOSIS'],
          'years_experience': 20,
          'consultation_rate': 100.00,
          'rating': 4.7,
        },
        'likes_count': 89,
        'comments_count': 23,
        'views': 567,
        'is_liked': false,
        'tags': ['disease-diagnosis', 'plant-health', 'crop-diseases'],
        'created_at': '2024-01-10T09:45:00Z',
        'published_at': '2024-01-12T16:30:00Z',
        'reading_time': '12 min read time',
      },
      {
        'id': '3',
        'title': 'Soil Health Management',
        'category': 'SOIL_HEALTH',
        'excerpt': 'Essential soil management for optimal crop yield',
        'content': 'Learn how to maintain soil health and fertility',
        'author': 'Dr. David Kim',
        'expert_name': 'Dr. David Kim',
        'author_profile': 'Soil Scientist with 12 years experience',
        'expert_profile': {
          'specialization': ['SOIL_HEALTH', 'NUTRIENT_MANAGEMENT', 'FERTILITY'],
          'years_experience': 12,
          'consultation_rate': 60.00,
          'rating': 4.6,
        },
        'likes_count': 156,
        'comments_count': 42,
        'views': 1234,
        'is_liked': false,
        'tags': ['soil-health', 'nutrients', 'fertility'],
        'created_at': '2024-01-08T14:20:00Z',
        'published_at': '2024-01-10T11:30:00Z',
        'reading_time': '8 min read time',
      },
    ],
    'recent_consultations': [
      {
        'id': '1',
        'topic': 'Pest Problem in Tomatoes',
        'description': 'Yellow spots appearing on tomato leaves',
        'farmer_id': 'farmer_123',
        'expert_id': 'expert_456',
        'farmer_name': 'John Farmer',
        'expert_name': 'Dr. Sarah Johnson',
        'consultation_type': 'ON_SITE',
        'scheduled_date': '2024-01-20T14:00Z',
        'duration_minutes': 60,
        'status': 'SCHEDULED',
        'priority': 'high',
        'created_at': '2024-01-20T10:30:00Z',
      },
      {
        'id': '2',
        'topic': 'Irrigation System Setup',
        'description': 'Need help setting up drip irrigation system',
        'farmer_id': 'farmer_456',
        'expert_id': 'expert_789',
        'farmer_name': 'Mary Wang',
        'expert_name': 'Dr. Michael Kim',
        'consultation_type': 'ON_SITE',
        'scheduled_date': '2024-01-25T09:00Z',
        'duration_minutes': 120,
        'priority': 'high',
        'created_at': '2024-01-25T09:00Z',
      },
      {
        'id': '3',
        'topic': 'Crop Rotation Planning',
        'description': 'Need advice on crop rotation schedule',
        'farmer_id': 'farmer_789',
        'expert_id': 'expert_456',
        'farmer_name': 'David Farmer',
        'expert_name': 'Dr. Sarah Johnson',
        'consultation_type': 'TEXT',
        'scheduled_date': '2024-01-26T11:30:00Z',
        'duration_minutes': 30,
        'priority': 'medium',
        'created_at': '2024-01-26T11:30:00Z',
      },
    ],
    'upcoming_consultations': [
      {
        'id': '4',
        'topic': 'Market Trends Analysis',
        'farmer_id': 'farmer_123',
        'expert_id': 'expert_456',
        'farmer_name': 'Alice Farmer',
        'expert_name': 'Dr. Sarah Johnson',
        'consultation_type': 'VIDEO',
        'scheduled_date': '2024-01-22T14:00Z',
        'duration_minutes': 45,
        'priority': 'medium',
        'created_at': '2024-01-22T14:00Z',
      },
      {
        'id': '5',
        'topic': 'Organic Certification Process',
        'farmer_id': 'farmer_123',
        'expert_id': 'expert_456',
        'farmer_name': 'Alice Farmer',
        'expert_name': 'Dr. Michael Kim',
        'consultation_type': 'TEXT',
        'priority': 'medium',
        'created_at': '2024-01-22T11:30:00Z',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Try to load real data from API
      final data = await _apiService.getDashboardData(role: UserRole.EXPERT);
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to mock data if API fails
      if (mounted) {
        setState(() {
          _dashboardData = _mockDashboardData;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: _buildBody(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        child: CustomIconWidget(
          iconName: 'psychology',
          color: Colors.white,
          size: 6.w,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      title: Text(
        'Expert Dashboard',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _showNotifications,
          icon: Icon(
            Icons.notifications_outlined,
            color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: _showProfileMenu,
          icon: Icon(
            Icons.person_outlined,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 2.w),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: publishedDate('2024-01-04T15:00Z'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          DashboardStatsWidget(
            stats: _dashboardData!['stats'],
            isFarmer: false,
            isExpert: true,
          ),
          SizedBox(height: 2.h),

          // Published Posts
          _buildSectionTitle('Your Published Posts'),
          SizedBox(height: 1.h),
          _buildPublishedPosts(),
          SizedBox(height: 3.h),

          // Consultations
          _buildSectionTitle('Upcoming Consultations'),
          SizedBox(height: 1.h),
          _buildUpcomingConsultations(),
          SizedBox(height: 3.h),

          // Recent Activities
          _buildSectionTitle('Recent Activity'),
          SizedBox(height: 1.h),
          RecentActivitiesWidget(
            activities: _dashboardData!['recent_activities'],
          ),
          SizedBox(height: 2.h),

          // Quick Actions
          _buildSectionTitle('Quick Actions'),
          SizedBox(height: 1.h),
          QuickActionsWidget(
            isFarmer: false,
            onCreateAdvice: _navigateToCreateAdvicePost,
            onViewConsultations: _navigateToConsultations,
            onViewPosts: _navigateToPosts(),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Text(
        title,
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPublishedPosts() {
    final posts = _dashboardData!['recent_posts'] as List<Map<String, dynamic>>;

    return ListView.builder(
      itemCount: posts.length,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _buildAdvicePostCard(posts[index]);
      },
    );
  }

  Widget _buildAdvicePostCard(Map<String, dynamic> post) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: BoxDecoration(
                color: _getCategoryColor(post['category'] as String),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post['category'] as String,
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 1.h),

            // Post Image
            if (post['image'] != null) ...[
              Container(
                height: 20.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                decoration: BoxDecoration(
                  image: DecorationImage(
                  image: NetworkImage(
                    post['image'] as String,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                ),
              ),
            ],

            // Post Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      post['title'] as String,
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),

                    // Excerpt
                    Text(
                      post['excerpt'] as String,
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),

                    // Metadata
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.grey[600],
                              size: 4.w,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Reading time: ${post['reading_time']}', // Format as needed
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          Expanded(
                            Text(
                              ' • ${post['views']} views',
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                      ],
                    ],
                    ),
                    SizedBox(height: 1.h),

                    // Tags
                    if (post['tags'] != null && post['tags'].isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Wrap(
                        spacing: 1.w,
                        runSpacing: 1.w,
                        children: [
                          for (var tag in post['tags']) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 1.w,
                                vertical: 0.5.h,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tag,
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ],
                        ),
                      SizedBox(height: 1.h),
                    ],

                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_border_outlined,
                          color: post['is_liked'] ? Colors.red : Colors.grey[600],
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${post['likes_count']} likes',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Icon(
                          Icons.share_outlined,
                          color: Colors.grey[600],
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${post['comments_count']} comments',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 1.w),
                      ],
                    ],
                    ),
                    SizedBox(height: 1.h),
                  ],
                ),
              ],
            ),
          ],
        ],
      );
    },
  }

  Color _getCategoryColor(String category) {
      switch (category.toUpperCase()) {
      case 'CROP_MANAGEMENT':
        return Colors.green;
      case 'PEST_CONTROL':
        return Colors.red;
      case 'IRRIGATION':
        Colors.blue;
      case 'SOIL_HEALTH':
        Colors.brown;
      case 'LIVESTOCK':
        Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _buildUpcomingConsultations() {
    final consultations = _dashboardData!['upcoming_consultations'] as List<Map<String, dynamic>>;

    return Container(
      height: 25.h,
      child: ListView.builder(
        itemCount: consultations.length,
        itemCount: consultations.length,
        itemBuilder: (context, index) => _buildConsultationCard(consultations[index]),
      ),
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> consultation) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  consultation['consultation_type'] as String,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                    decoration: BoxDecoration(
                      color: _getStatusColor(consultation['status'] as String),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      consultation['consultation_type_display'] as String,
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ),
              ],
            ),
            SizedBox(height: 1.h),

            // Consultation Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getConsultationTypeIcon(consultation['consultation_type'] as String),
                  color: _getConsultationTypeColor(consultation['consultation_type'] as String),
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                  consultation['consultation_type_display'] as String,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ],
              SizedBox(width: 2.w),
              Icon(
                Icons.schedule_outlined,
                color: Colors.grey[600],
                size: 5.w),
                SizedBox(width: 1.w),
                Text(
                  'Scheduled for ${consultation['scheduled_date']}', style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              ),
            ],
          ],

            // Price Information
            if (consultation['consultation_rate'] != null) ...[
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                  'Consultation Rate:',
                  style: AppTheme.lightTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  '\$${consultation['consultation_rate']}/hour',
                  style: AppTheme.lightTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              ],
              SizedBox(height: 1.h),

            // Customer Information
            Row(
              children: [
                Text(
                  'Customer: ${consultation['farmer_name']}', style: AppTheme.lightTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
                SizedBox(width: 2.w),
                Text(
                  'Location: ${consultation['location']}', style: AppTheme.lightTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            ],
            SizedBox(height: 1.h),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => _scheduleConsultation(consultation),
                  style: ElevatedButton.styleFromDefault(
                    backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    'Schedule Session',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                ),
                SizedBox(width: 2.w),
                OutlinedButton(
                  onPressed: () => _rejectConsultation(consultation),
                  style: ElevatedButton.styleFromDefault(
                    backgroundColor: Colors.red,
                    child: Text(
                      'Reject Request',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                  ),
                ),
                SizedBox(width: 2.w),
                OutlinedButton(
                  onPressed: () => _acceptConsultation(consultation),
                  style: ElevatedButton.fromDefault(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      'Accept Request',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getConsultationTypeIcon(String consultationType) {
    switch (consultation_type.toUpperCase()) {
      case 'TEXT':
        return Icons.message;
      case 'VIDEO':
        Icons.video_call;
      case 'AUDIO':
        Icons.phone_in_talk;
      case 'ON_SITE':
        Icons.location_on_map;
      default:
        Icons.chat_bubble_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REQUESTED':
        return Colors.orange;
      case 'SCHEDULED':
        Colors.blue;
      case 'IN_PROGRESS':
        Colors.purple;
      case 'COMPLETED':
        Colors.green;
      case 'CANCELLED':
        Colors.red;
      default:
        Colors.grey;
    }
  }

  Future<void> _scheduleConsultation(Map<String, dynamic> consultation) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Consultation scheduled successfully for ${consultation['scheduled_date']}',
      backgroundColor: AppTheme.getSuccessColor(true),
      ),
    );
  }

  Future<void> _rejectConsultation(Map<String, dynamic> consultation) async {
    ScaffoldMessenger.of(context).showSnackBar(
      content: 'Consultation request rejected',
      backgroundColor: AppTheme.getErrorColor(true),
    );
  }

  Future<void> _acceptConsultation(Map<String, dynamic> consultation) async {
    ScaffoldMessenger.of(context).showSnackBar(
      content: 'Consultation accepted! Expert will contact you soon',
      backgroundColor: AppTheme.getSuccessColor(true),
    );
  }

  void _acceptConsultation(Map<String, dynamic> consultation) {
    // Accept consultation request
    consultation['status'] = 'ACCEPTED';
    ScaffoldMessenger.of(context).showSnackBar(
      content: 'Consultation request accepted! Expert will contact you soon',
      backgroundColor: AppTheme.getSuccessColor(true),
    );
  }

  Future<void> _navigateToCreateAdvicePost() {
    Navigator.pushNamed(context, '/experts/advice/create');
  }

  void _navigateToConsultations() {
    Navigator.pushNamed(context, '/experts/consultations');
  }

  void _navigateToPosts() {
    Navigator.pushNamed(context, '/experts/advice');
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 30.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(10),
              ),
            ),
            ),
            Text(
              'Quick Actions',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 2.w,
              crossAxisSpacing: 2.w,
              childAspectRatio: 1.2,
              children: [
                _buildQuickActionCard(
                  'Create\nAdvice\nPost',
                  Icons.add_circle_outlined,
                  Colors.green,
                  () => _navigateToCreateAdvicePost(),
                ),
                _buildQuickActionCard(
                  'View\nConsultations',
                  Icons.people_outlined,
                  Colors.blue,
                  () => _navigateToConsultations(),
                ),
                _buildQuickActionCard(
                  'View\nStatistics',
                  Icons.analytics_outlined,
                  Colors.orange,
                  () => _navigateToStatistics(),
                ),
                _buildQuickActionCard(
                  'Share\nExpertise',
                  Icons.share_outlined,
                  Colors.purple,
                  () => _shareContent(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareContent() {
    // Share content functionality
    ScaffoldMessenger.of(context).showSnackBar(
      content: 'Share functionality coming soon!',
    );
  }

  void _navigateToStatistics() {
    Navigator.pushNamed(context, '/dashboard/statistics');
  }

  @override
  void dispose() {
    super.dispose();
  }
}