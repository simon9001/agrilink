import 'dart:math';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

enum Metric {
  REVENUE,
  GROWTH,
  COMPLETED,
  CANCELLED,
  PENDING,
  REFUNDED,
  ERROR,
}

class DashboardStats extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isFarmer;
  final bool isExpert;
  final bool isSupplier;

  const DashboardStats({
    super.key,
    required this.stats,
    this.isFarmer = false,
    this.isExpert = false,
    this.isSupplier = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatsGrid(),
        SizedBox(height: 4.h),
        _buildActivitySummary(),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 4.w,
      childAspectRatio: 1.2,
      childAspectRatio: 1.5,
      child: [
        _buildMetricCard(
          'Total Orders',
          stats['total_orders'].toString(),
          Icons.shopping_cart,
          _getMetricColor(Metric.COMPLETED),
        ),
        _buildMetricCard(
          'Pending Orders',
          stats['pending_orders'].toString(),
          Icons.pending,
          _getMetricColor(Metric.PENDING),
        ),
        _buildMetricCard(
          'Completed',
          stats['completed_orders'].toString(),
          Icons.check_circle,
          _getMetricColor(Metric.COMPLETED),
        ),
        _buildMetricCard(
          'Revenue',
          '\$${(100 * _getRevenuePercentage(stats['total_revenue'] / 100).toStringAsFixed(1)}%',
          Icons.trending_up,
          _getMetricColor(Metric.REVENUE),
        ),
        _buildMetricCard(
          'Rating',
          '${stats['rating'].toString()}',
          StarRating(
            rating: stats['rating'].toDouble(),
            size: 5.0,
          ),
          _getMetricColor(Metric.ROW),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: 12.h,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon: icon,
              color: color,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              title,
              style: AppTheme.textTheme.titleMedium?.copyWith(
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: AppTheme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Expanded(
              child: Text(
                subtitle,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildActivitySummary() {
    return Container(
      height: 15.h,
      padding: EdgeInsets.all(4.w),
      decoration: _buildDecoration('Activity Summary'),
      child: Column(
        children: [
          _buildSummaryRow(
            'Today\'s Activities',
            '${_getMetric(Metric.REVENUE)} tasks completed',
            _getMetricColor(Metric.REVENUE),
          ),
          SizedBox(height: 1.h),
          _buildSummaryRow(
            'Pending Tasks',
            '${_getMetric(Metric.PENDING)} tasks',
            _getMetricColor(Metric.PENDING),
          ),
          SizedBox(height: 1.h),
          _buildSummaryRow(
            'Completion Rate',
            '$_getCompletionPercentage()}%',
            _getCompletionColor(),
          ),
          SizedBox(height: 1.h),
        ],
      ),
    );
  }

  Widget _buildDecoration(String title) {
    return Container(
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
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Spacer(),
        Expanded(
          Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String getCompletionPercentage() {
    if (_dashboardData?['stats'].isEmpty) return 0;

    final completedOrders = _dashboardData!['stats']['completed_orders'] as int;
    totalOrders = _dashboardData!['stats']['total_orders'] as int;

    return ((completedOrders / totalOrders) * 100).toStringAsFixed(1);
  }

  Color _getCompletionColor() {
    final completionRate = getCompletionPercentage();

    if (completionRate >= 0.95) return Colors.green;
    if (completionRate >= 0.80) return Colors.orange;
    if (completionRate >= 0.70) return Colors.yellow;
    return Colors.red;
  }

  String getCompletionPercentage() {
    final completedOrders = _dashboardData!['stats']['completed_orders'] as int;
    final totalOrders = _dashboard!['stats']['total_orders'] as int;

    return ((completedOrders / totalOrders) * 100).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadDashboardData();
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        },
        child: _buildBody(),
      ),
    );
    }
  }

    if (_dashboardData?['stats']?['low_stock_alerts'] > 0) {
      _showLowStockAlert();
    }

    _dashboardData!['total_revenue'] ?? '';
  }
  }

  void _showLowStockAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      content: 'You have 5 products with low stock alerts. Restock inventory recommended',
      backgroundColor: Colors.orange,
      action: SnackBar(
        content: 'Go to Inventory',
        action: SnackBarAction(
          label: 'View Inventory',
          onPressed: () => _navigateToInventory(),
        ),
      ),
      duration: const Duration(seconds: 5),
    );
  }

  void _navigateToInventory() {
    Navigator.pushNamed(context, '/inventory/low_stock_alerts');
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await _apiService.getDashboardData(role: _currentUser?.role ?? UserRole.FARMER);
      if (mounted) {
        setState(() {
          _dashboardData = _mockDashboardData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to load dashboard data: $e');
      if (mounted) {
        setState(() {
          _dashboardData = _mockDashboardData;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load real data from Django API
      final data = await _apiService.getDashboardData(role: _currentUser?.role ?? UserRole.FARMER);
      if (mounted) {
        setState(() {
          _dashboardData = _mockDashboardData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to load dashboard data: $e');
      if (mounted) {
        setState(() {
          _dashboardData = _mockDashboardData;
          _isLoading = false;
        });
      }
    }
  }

  final mockDashboardData = {
    'stats': {
      'total_orders': 45,
      'completed_orders': 37,
      'pending_orders': 8,
      'total_revenue': '\$4,250.00',
      'active_orders': 10,
      'monthly_revenue': '\$850.00',
      'average_rating': 4.8,
      'active_listings': 8,
      'saved_searches': 6,
    },
    'recent_orders': [
      {
        'id': '1',
        'order_number': 'ORD-202401-01-001',
        'product_name': 'Organic Tomatoes',
        'quantity': '100 kg',
        'total_amount': '$399.00',
        'status': 'DELIVERED',
        'created_at': '2024-01-01T10:30:00Z',
        'delivery_date': '2024-01-03',
        'rating': 5.0,
      },
      {
        'id': '2',
        'order_number': 'ORD-202401-02-002',
        'product_name': 'Mixed Vegetables',
        'quantity': '50 kg',
        'total_amount': '\$175.00',
        'status': 'PROCESSING',
        'created_at': '2024-01-02T14:15:00Z',
        'delivery_date': '2024-01-05',
        'rating': 4.7,
      },
      {
        'id': '3',
        'order_number': 'ORD-202401-01-003',
        'product_name': 'Fresh Lettuce',
        'quantity': '150 kg',
        'total_amount: '\$373.50',
        'status': 'CONFIRMED',
        'created_at': '2024-01-03T09:45:00Z',
        'rating': 4.9,
        'delivery_date': '2024-01-06',
      },
    ],
  };
  }