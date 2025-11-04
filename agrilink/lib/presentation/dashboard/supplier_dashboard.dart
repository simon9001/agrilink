import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../services/django_api_service.dart';
import '../../core/user_role.dart';
import '../dashboard/widgets/dashboard_stats_widget.dart';
import '../dashboard/widgets/recent_activities_widget.dart';
import '../dashboard/widgets/quick_actions_widget.dart';
import '../dashboard/widgets/inventory_widget.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({Key? key}) : super(key: key);

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  final DjangoApiService _apiService = DjangoApiService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  // Mock data for development
  final Map<String, dynamic> _mockDashboardData = {
    'stats': {
      'total_products': 156,
      'active_products': 89,
      'out_of_stock': 12,
      'low_stock_alerts': 5,
      'total_inquiries': 45,
      'pending_orders': 8,
      'monthly_revenue': '\$12,750',
      'completed_orders': 37,
      'average_rating': 4.7,
      'verified_products': 45,
      'service_areas': [
        'Nairobi', 'Nakuru', 'Mombasa', 'Kisumu',
      ],
    },
    'inventory': [
      {
        'id': '1',
        'name': 'Organic Fertilizer (NPK 10-20-20)',
        'stock_quantity': 500,
        'low_stock_threshold': 100,
        'price': '\$45.00',
        'category': 'FERTILIZERS',
        'supplier': 'AgriSupplies Ltd',
        'location': 'Nairobi',
        'reorder_level': 'Low',
      },
      {
        'id': '2',
        'name': 'Premium Seeds (Hybrid Maize)',
        'stock_quantity': 1000,
        'low_stock_threshold': 200,
        'price': '\$120.00',
        'category': 'SEEDS',
        'supplier': 'SeedCo Kenya',
        'location': 'Eldoret',
        'reorder_level': 'Medium',
      },
      {
        'id': '3',
        'name': 'Drip Irrigation System',
        'stock_quantity': 50,
        'low_stock_threshold': 10,
        'price': '\$250.00',
        'category': 'IRRIGATION',
        'supplier': 'Irrigation Solutions',
        'location': 'Nairobi',
        'reorder_level': 'Low',
      },
      {
        'id': '4',
        'name': 'Crop Protection Kit',
        'stock_quantity': 200,
        'low_stock_threshold': 50',
        'price': '\$35.00',
        'category': 'TOOLS',
        'supplier': 'AgriTools',
        'location': 'Nairobi',
        'reorder_level': 'Low',
      },
    ],
    'recent_inquiries': [
      {
        'id': '1',
        'farmer_name': 'John Farmer',
        'product_type': 'Fertilizer',
        'product_name': 'Organic Fertilizer',
        'quantity': '50kg',
        'location': 'Nairobi',
        'message': 'Need advice on application schedule',
        'timestamp': '2 hours ago',
        'priority': 'medium',
      },
      {
        'id': '2',
        'farmer_name': 'Mary Farmer',
        'product_type': 'Seeds',
        'product_name': 'Hybrid Maize Seeds',
        'quantity': '25kg',
        'location': 'Thika',
        'message': 'Availability and pricing inquiry',
        'timestamp': '5 hours ago',
        'priority': 'high',
      },
      {
        'id': '3',
        'farmer_name': 'David Farmer',
        'product_type': 'TOOLS',
        'product_name': 'Drip Irrigation System',
        'quantity': '1 unit',
        'location': 'Kajiado',
        'message': 'Installation and training required',
        'timestamp': '1 day ago',
        'priority': 'high',
      },
    ],
    'recent_orders': [
      {
        'id': '1',
        'order_number': 'SUP-20240101-001',
        'customer_name': 'John Farmer',
        'product_name': 'Organic Fertilizer (NPK)',
        'quantity': '50kg',
        'total_amount': '\$2,250',
        'status': 'PROCESSING',
        'created_at': '2024-01-01T10:30:00Z',
        'delivery_date': '2024-01-03',
      },
      {
        'id': '2',
        'order_number': 'SUP-20240102-002',
        'customer_name': 'Mary Farmer',
        'product_name': 'Hybrid Maize Seeds',
        'quantity': '25kg',
        'total_amount': '\$3,000',
        'status': 'CONFIRMED',
        'created_at': '2024-01-02T14:15:00Z',
        'delivery_date': '2024-01-05',
      },
    ],
    'service_requests': [
      {
        'id': '1',
        'farmer_name': 'David Farmer',
        'service_type': 'IRRIGATION',
        'description': 'Drip irrigation system installation',
        'location': 'Kajiado',
        'timestamp': '2 days ago',
        'priority': 'high',
      },
      {
        'id': '2',
        'farmer_name': 'Sarah Farmer',
        'service_type': 'CONSULTATION',
        'description': 'Crop disease diagnosis',
        'location': 'Nakuru',
        'timestamp': '3 days ago',
        'priority': 'medium',
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
      final data = await _apiService.getDashboardData(role: UserRole.SUPPLIER);
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
          iconName: 'inventory',
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
        'Supplier Dashboard',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          DashboardStatsWidget(
            stats: _dashboardData!['stats'],
            isFarmer: false,
          ),
          SizedBox(height: 2.h),

          // Inventory Status
          _buildSectionTitle('Inventory Status'),
          SizedBox(height: 1.h),
          _buildInventoryStatus(),
          SizedBox(height: 2.h),

          // Low Stock Alerts
          if (_dashboardData!['stats']['low_stock_alerts'] > 0) ...[
            _buildLowStockAlerts(),
            SizedBox(height: 2.h),
          ],

          // Service Requests
          _buildSectionTitle('Service Requests'),
          SizedBox(height: 1.h),
          _buildServiceRequests(),
          SizedBox(height: 3.h),

          // Recent Orders
          _buildSectionTitle('Recent Orders'),
          SizedBox(height: 1.h),
          _buildRecentOrders(),
          SizedBox(height: 3.h),

          // Recent Inquiries
          _buildSectionTitle('Recent Inquiries'),
          SizedBox(height: 1.h),
          _buildRecentInquiries(),
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
            onCreateProduct: _navigateToCreateProduct,
            onViewOrders: _navigateToOrders,
            onViewInquiries: _navigateToInquiries,
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

  Widget _buildInventoryStatus() {
    final alerts = _dashboardData!['stats']['low_stock_alerts'] as int;

    if (alerts == 0) {
      return Container(
        height: 15.h,
        child: Center(
          child: Text(
            'All products are well stocked',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 20.h,
      child: ListView.builder(
        itemCount: alerts,
        itemBuilder: (context, index) {
          return _buildLowStockAlert(index);
        },
      ),
    );
  }

  Widget _buildLowStockAlert(int index) {
    final alerts = _dashboardData!['stats']['low_stock_alerts'] as List;
    final alert = alerts[index];

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.orange,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Low Stock Alert',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
            IconButton(
              icon: Icons.info_outline,
              color: Colors.blue,
              size: 5.w,
              onPressed: () => _showStockDetails(alert),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockDetails(Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Low Stock Alert'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              alert['message'] as String,
              style: AppTheme.lightTheme.textTheme.bodyLarge,
            ),
            SizedBox(height: 2.h),
            Text(
              'Product: ${alert['product_name']}',
              style: AppTheme.textTheme.bodyMedium,
            ),
            Text(
              'Current Stock: ${alert['stock_quantity']}',
              'Current Level: ${alert['reorder_level']}',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Supplier: ${alert['supplier']}',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Location: ${alert['location']}',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('View Details'),
          ),
          ElevatedButton(
            onPressed: () => _reorderStock(alert),
            child: Text('Reorder Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reorderStock(Map<String, dynamic> alert) async {
    // Implement reorder functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Reorder functionality coming soon!',
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildServiceRequests() {
    final requests = _dashboardData!['recent_inquiries'] as List<Map<String, dynamic>>;

    return Container(
      height: 30.h,
      child: ListView.builder(
        itemCount: requests.length,
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildServiceRequestCard(requests[index]);
        },
      ),
    );
  }

  Widget _buildServiceRequestCard(Map<String, dynamic> request) {
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
              children: [
                Icon(
                  _getServiceTypeIcon(request['product_type'] as String),
                  color: _getServiceTypeColor(request['product_type'] as String),
                  size: 6.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    request['message'] as String,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Customer: ${request['farmer_name']}',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Location: ${request['location']}',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Priority: ${request['priority']}',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: _getPriorityColor(request['priority'] as String),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 2.w),
                IconButton(
                  icon: Icons.open_in_new,
                  color: Colors.blue,
                  onPressed: () => _handleServiceRequest(request),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getServiceTypeIcon(String productType) {
    switch (productType.toLowerCase()) {
      case 'fertilizer':
        return Icons.eco;
      case 'seeds':
        return Icons.grain;
      case 'tools':
        return Icons.build;
      case 'machinery':
        return settings.agricultural_machinery;
      case 'irrigigation':
        return Icons.water_drop;
      case 'packaging':
        return inventory_2;
      default:
        return Icons.category;
    }
  }

  Color _getServiceTypeColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleServiceRequest(Map<String, dynamic> request) {
    // Handle service request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Service request functionality coming soon!',
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRecentOrders() {
    final orders = _dashboardData!['recent_orders'] as List<Map<String, dynamic>>;

    return Container(
      height: 30.h,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
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
                Expanded(
                  child: Text(
                    order['order_number'] as String,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status'] as String),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['status'] as String,
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Customer: ${order['buyer_name']}',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Product: ${order['product_name']} (${order['quantity']}kg)',
              style: AppTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${order['total_amount']}',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.primaryColor,
                  ),
                ),
                Text(
                  order['delivery_date'],
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (order['delivery_date'] != null) ...[
              SizedBox(height: 0.5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.blue,
                ),
                  SizedBox(width: 2.w),
                  Text(
                    'Delivery: ${order['delivery_date']}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icons.message_outlined,
                  color: Colors.blue,
                  onPressed: () => _showOrderChat(order),
                ),
                IconButton(
                  icon: Icons.rate_review_outlined,
                  color: Colors.amber,
                  onPressed: () => _showReviewDialog(order),
                ),
                SizedBox(width: 2.w),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderChat(Map<String, dynamic> order) {
    // Order chat functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Order chat functionality coming soon!',
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> order) {
    // Review functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Review functionality coming soon!',
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              'Notifications',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: Colors.blue,
                  ),
                  title: 'Price alert for maize prices',
                  subtitle: 'Prices dropped by 5%',
                  trailing: Icon(Icons.trending_up, color: Colors.orange),
                  onTap: () => _navigateToMarketPrices(),
                ),
                ListTile(
                  leading: Icon(
                    Icons.favorite_border,
                    color: Colors.red,
                  ),
                  title: 'New farmer joined platform',
                  subtitle: 'Mary Johnson from Green Valley Farm',
                  trailing: Icon(Icons.person_add, color: Colors.blue),
                ),
                ListTile(
                  leading: Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.blue,
                  ),
                  title: 'Delivery scheduled for tomorrow',
                  subtitle: 'Your order will be delivered tomorrow',
                  trailing: Icon(Icons.local_shipping_outlined, color: Colors.blue),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _navigateToMarketPrices() {
    Navigator.pushNamed(context, '/market-prices');
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 25.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              'Profile',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  _apiService.currentUser?.profilePicture ?? '',
                ),
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, color: Colors.grey[600]),
              ),
              title: Text(
                _apiService.currentUser?.fullName ?? 'User',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              subtitle: Text(
                _apiService.currentUser?.role?.displayName ?? 'Buyer',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              onTap: () => Navigator.pushNamed(context, AppRoutes.userProfile),
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: Colors.grey[600],
              ),
              title: 'Settings',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            ListTile(
              leading: Icon(
                Icons.help_outline,
                color: Colors.grey[600],
              ),
              title: 'Help & Support',
              onTap: () => Navigator.pushNamed(context, '/help'),
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: 'Logout',
              onTap: () => _showLogoutConfirmation(),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _apiService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}