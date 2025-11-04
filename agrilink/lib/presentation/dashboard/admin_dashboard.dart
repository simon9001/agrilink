import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import 'widgets/dashboard_stats_widget.dart';
import 'widgets/recent_activities_widget.dart';
import 'widgets/quick_actions_widget.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _systemActivities = [];
  List<Map<String, dynamic>> _pendingTasks = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _dashboardData = _getMockDashboardData();
        _systemActivities = _getMockSystemActivities();
        _pendingTasks = _getMockPendingTasks();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/admin/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/admin/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading ? _buildLoadingState() : _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.dashboard),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 2.h),
          Text(
            'Loading dashboard...',
            style: AppTheme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          SizedBox(height: 3.h),
          _buildSystemOverview(),
          SizedBox(height: 3.h),
          DashboardStats(
            stats: _dashboardData['stats'] ?? {},
            isFarmer: false,
            isExpert: false,
            isSupplier: false,
          ),
          SizedBox(height: 3.h),
          QuickActionsWidget(
            actions: _getAdminQuickActions(),
            title: 'Admin Actions',
          ),
          SizedBox(height: 3.h),
          RecentActivitiesWidget(
            activities: _systemActivities,
            title: 'System Activities',
          ),
          SizedBox(height: 3.h),
          _buildPendingTasks(),
          SizedBox(height: 3.h),
          _buildSystemHealth(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Admin',
                      style: AppTheme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'System Management Dashboard',
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'System Status',
                  'All Systems Operational',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStatusCard(
                  'Active Users',
                  '${_dashboardData['active_users'] ?? '0'}',
                  Colors.blue,
                  Icons.people,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 4.w),
          SizedBox(width: 1.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  value,
                  style: AppTheme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOverview() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Overview',
            style: AppTheme.texttheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  'Total Users',
                  '${_dashboardData['total_users'] ?? '0'}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Active Listings',
                  '${_dashboardData['active_listings'] ?? '0'}',
                  Icons.list_alt,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Total Orders',
                  '${_dashboardData['total_orders'] ?? '0'}',
                  Icons.shopping_cart,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  'Revenue',
                  '\$${_dashboardData['total_revenue'] ?? '0'}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Support Tickets',
                  '${_dashboardData['support_tickets'] ?? '0'}',
                  Icons.support_agent,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  'System Load',
                  '${_dashboardData['system_load'] ?? '0'}%',
                  Icons.memory,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 5.w),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: AppTheme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTasks() {
    if (_pendingTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Tasks',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_pendingTasks.length}',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Column(
            children: _pendingTasks.take(3).map((task) {
              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      task['priority'] == 'high' ? Icons.priority_high : Icons.task,
                      color: task['priority'] == 'high' ? Colors.red : Colors.orange,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'] as String,
                            style: AppTheme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            task['description'] as String,
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _handleTaskAction(task),
                      child: Text('Handle'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Health',
            style: AppTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildHealthItem('Database', 'Operational', Colors.green),
          _buildHealthItem('API Server', 'Operational', Colors.green),
          _buildHealthItem('File Storage', 'Operational', Colors.green),
          _buildHealthItem('Email Service', 'Operational', Colors.green),
          _buildHealthItem('Background Jobs', 'Running', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String service, String status, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: color,
            size: 2.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              service,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            status,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Admin Actions',
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ..._getAdminQuickActions().map((action) {
              return ListTile(
                leading: Icon(action['icon'] as IconData),
                title: Text(action['title'] as String),
                onTap: () {
                  Navigator.pop(context);
                  _handleActionTap(action);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _handleActionTap(Map<String, dynamic> action) {
    final route = action['route'] as String?;

    if (route != null) {
      Navigator.pushNamed(context, route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action "${action['title']}" not implemented yet'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleTaskAction(Map<String, dynamic> task) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Handling task: ${task['title']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  List<Map<String, dynamic>> _getAdminQuickActions() {
    return [
      {
        'title': 'User Management',
        'description': 'Manage user accounts and permissions',
        'icon': Icons.people,
        'color': Colors.blue,
        'route': '/admin/users',
      },
      {
        'title': 'System Settings',
        'description': 'Configure system parameters',
        'icon': Icons.settings,
        'color': Colors.purple,
        'route': '/admin/settings',
      },
      {
        'title': 'Analytics',
        'description': 'View system analytics and reports',
        'icon': Icons.analytics,
        'color': Colors.green,
        'route': '/admin/analytics',
      },
      {
        'title': 'Support Tickets',
        'description': 'Handle customer support requests',
        'icon': Icons.support_agent,
        'color': Colors.orange,
        'route': '/admin/support',
      },
      {
        'title': 'Content Moderation',
        'description': 'Review and moderate user content',
        'icon': Icons.content_paste,
        'color': Colors.red,
        'route': '/admin/moderation',
      },
      {
        'title': 'System Logs',
        'description': 'View system logs and monitoring',
        'icon': Icons.list_alt,
        'color': Colors.teal,
        'route': '/admin/logs',
      },
    ];
  }

  Map<String, dynamic> _getMockDashboardData() {
    return {
      'stats': {
        'total_orders': 1247,
        'completed_orders': 1098,
        'pending_orders': 149,
        'total_revenue': '\$125,430',
        'today_activities': 45,
        'pending_tasks': 8,
        'rating': 4.7,
      },
      'total_users': 3847,
      'active_users': 1247,
      'active_listings': 892,
      'total_orders': 1247,
      'total_revenue': '\$125,430',
      'support_tickets': 23,
      'system_load': '67',
    };
  }

  List<Map<String, dynamic>> _getMockSystemActivities() {
    return [
      {
        'type': 'user',
        'title': 'New User Registration',
        'description': 'John Doe registered as a farmer',
        'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'status': 'completed',
      },
      {
        'type': 'order',
        'title': 'Large Order Placed',
        'description': 'Order #12345 for \$2,500 worth of produce',
        'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'status': 'processing',
      },
      {
        'type': 'system',
        'title': 'System Backup Completed',
        'description': 'Daily backup completed successfully',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'status': 'completed',
      },
      {
        'type': 'consultation',
        'title': 'Expert Consultation Request',
        'description': 'Dr. Smith requested for crop disease consultation',
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'status': 'pending',
      },
      {
        'type': 'payment',
        'title': 'Payment Processed',
        'description': 'Payment of \$450 processed for order #12344',
        'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        'status': 'completed',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockPendingTasks() {
    return [
      {
        'title': 'Verify New Farmer',
        'description': 'Review and approve 3 pending farmer applications',
        'priority': 'high',
        'type': 'user_verification',
      },
      {
        'title': 'Resolve Payment Dispute',
        'description': 'Order #12340 - Buyer claims delivery not received',
        'priority': 'high',
        'type': 'dispute_resolution',
      },
      {
        'title': 'Review Content Report',
        'description': 'User reported inappropriate content in marketplace',
        'priority': 'medium',
        'type': 'content_moderation',
      },
    ];
  }
}