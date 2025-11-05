import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../services/django_api_service.dart';
import '../../core/user_role.dart';
import '../../widgets/custom_image_widget.dart';
import '../../widgets/custom_icon_widget.dart';
import '../dashboard/widgets/dashboard_stats_widget.dart';
import '../dashboard/widgets/recent_activities_widget.dart';
import '../dashboard/widgets/quick_actions_widget.dart';
import '../dashboard/widgets/weather_widget.dart';
import '../dashboard/widgets/market_prices_widget.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({Key? key}) : super(key: key);

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerState extends State<FarmerDashboard> {
  final DjangoApiService _apiService = DjangoApiService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  // Mock data for development
  final Map<String, dynamic> _mockDashboardData = {
    'stats': {
      'active_listings': 8,
      'total_orders': 24,
      'monthly_revenue': '\$4,250',
      'pending_orders': 3,
      'completed_orders': 21,
      'average_order_value': '\$125.00',
      'rating': 4.8,
      'total_products': 156,
    },
    'recent_listings': [
      {
        'id': '1',
        'product_name': 'Organic Tomatoes',
        'quantity': '500 kg',
        'unit_price': '\$3.99',
        'status': 'ACTIVE',
        'views': 45,
        'inquiries': 8,
        'image': 'https://images.pexels.com/photos/1300972/pexels-photo-1300972.jpeg?auto=compress&cs=tinysrgb&w=400',
        'expires_at': '2024-01-30',
      },
      {
        'id': '2',
        'product_name': 'Fresh Lettuce',
        'quantity': '300 kg',
        'unit_price': '\$2.49',
        'status': 'ACTIVE',
        'views': 32,
        'inquiries': 5,
        'image': 'https://images.pexels.com/photos/1459339/pexels-photo-1459339.jpeg?auto=compress&cs=tinysrgb&w=400',
        'expires_at': '2024-01-25',
      },
      {
        'id': '3',
        'product_name': 'Bell Peppers',
        'quantity': '200 kg',
        'unit_price': '\$4.99',
        'status': 'ACTIVE',
        'views': 28,
        'inquiries': 12,
        'image': 'https://images.unsplash.com/photo-1441997556409-4ae437439a2e?auto=compress&cs=tinysrgb&w=400',
        'expires_at': '2024-01-28',
      },
    ],
    'recent_orders': [
      {
        'id': '1',
        'order_number': 'ORD-20240101-001',
        'buyer_name': 'Fresh Market Inc',
        'product_name': 'Organic Tomatoes',
        'quantity': '100 kg',
        'total_amount': '\$399.00',
        'status': 'DELIVERED',
        'created_at': '2024-01-01T10:30:00Z',
        'delivery_date': '2024-01-03',
      },
      {
        'id': '2',
        'order_number': 'ORD-20240102-002',
        'buyer_name': 'Green Grocers',
        'product_name': 'Mixed Vegetables',
        'quantity': '50 kg',
        'total_amount': '\$175.00',
        'status': 'CONFIRMED',
        'created_at': '2024-01-02T14:15:00Z',
        'delivery_date': '2024-01-05',
      },
      {
        'id': '3',
        'order_number': 'ORD-20240103-003',
        'buyer_name': 'Restaurant Chain',
        'product_name': 'Fresh Lettuce',
        'quantity': '150 kg',
        'total_amount': '\$373.50',
        'status': 'PROCESSING',
        'created_at': '2024-01-03T09:45:00Z',
        'delivery_date': '2024-01-06',
      },
    ],
    'weather': {
      'temperature': '28°C',
      'condition': 'Partly Cloudy',
      'humidity': '65%',
      'forecast': [
        {
          'day': 'Tomorrow',
          'high': '30°C',
          'low': '22°C',
          'condition': 'Sunny',
          'icon': 'sunny',
        },
        {
          'day': 'Thursday',
          'high': '32°C',
          'low': '24°C',
          'condition': 'Partly Cloudy',
          'icon': 'cloudy',
        },
        {
          'day': 'Friday',
          'high': '29°C',
          'low': '23°C',
          'condition': 'Rainy',
          'icon': 'rainy',
        },
      ],
      'alerts': [
        {
          'type': 'warning',
          'message': 'High temperatures expected tomorrow. Consider providing shade for crops.',
          'severity': 'medium',
        },
        {
          'type': 'info',
          'message': 'Good day for harvesting leafy vegetables.',
          'severity': 'low',
        },
      ],
    },
    'market_prices': {
      'tomatoes': {
        'current': '\$3.99/kg',
        'change': '+0.15',
        'trend': 'up',
      },
      'lettuce': {
        'current': '\$2.49/kg',
        'change': '-0.10',
        'trend': 'down',
      },
      'peppers': {
        'current': '\$4.99/kg',
        'change': '+0.25',
        'trend': 'up',
      },
      'maize': {
        'current': '\$0.45/kg',
        'change': '0.00',
        'trend': 'stable',
      },
    },
    'recent_activities': [
      {
        'id': '1',
        'type': 'order',
        'message': 'New order for Organic Tomatoes',
        'timestamp': '2 hours ago',
        'icon': 'shopping_cart',
        'priority': 'high',
      },
      {
        'id': '2',
        'type': 'inquiry',
        'message': 'Inquiry about Bell Peppers from Fresh Market',
        'timestamp': '3 hours ago',
        'icon': 'question_answer',
        'priority': 'medium',
      },
      {
        'id': '3',
        'type': 'listing_view',
        'message': 'Someone viewed your tomato listing',
        'timestamp': '5 hours ago',
        'icon': 'visibility',
        'priority': 'low',
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
      final data = await _apiService.getDashboardData(role: UserRole.FARMER);
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
          iconName: 'add',
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
        'Farmer Dashboard',
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
          // Weather Widget
          WeatherWidget(
            weatherData: _dashboardData!['weather'],
          ),
          SizedBox(height: 2.h),

          // Quick Stats
          DashboardStatsWidget(
            stats: _dashboardData!['stats'],
            isFarmer: true,
          ),
          SizedBox(height: 2.h),

          // Market Prices
          MarketPricesWidget(
            marketData: _dashboardData!['market_prices'],
          ),
          SizedBox(height: 2.h),

          // Recent Listings
          _buildSectionTitle('Your Active Listings'),
          SizedBox(height: 1.h),
          _buildRecentListings(),
          SizedBox(height: 3.h),

          // Recent Orders
          _buildSectionTitle('Recent Orders'),
          SizedBox(height: 1.h),
          _buildRecentOrders(),
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
            isFarmer: true,
            onCreateListing: _navigateToCreateListing,
            onViewOrders: _navigateToOrders,
            onManageProducts: _navigateToProducts,
          ),
        ],
      ),
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

  Widget _buildRecentListings() {
    final listings = _dashboardData!['recent_listings'] as List<Map<String, dynamic>>;

    return Container(
      height: 20.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: listings.length,
        itemBuilder: (context, index) {
          return _buildListingCard(listings[index]);
        },
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    return Container(
      width: 30.w,
      margin: EdgeInsets.only(right: 2.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            height: 12.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              image: DecorationImage(
                image: NetworkImage(listing['image'] as String),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing['product_name'] as String,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${listing['quantity']} • ${listing['unit_price']}',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      listing['status'] as String,
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(listing['status'] as String),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${listing['views']} views',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Icon(
                      Icons.remove_red_eye_outlined,
                      size: 4.w,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 1.w),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 4.w,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${listing['inquiries']} inquiries',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'SOLD':
        return Colors.grey;
      case 'EXPIRED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecentOrders() {
    final orders = _dashboardData!['recent_orders'] as List<Map<String, dynamic>>;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
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
              'Buyer: ${order['buyer_name']}',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Product: ${order['product_name']} (${order['quantity']})',
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
                  order['created_at'],
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (order['delivery_date'] != null) ...[
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 4.w,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Delivery: ${order['delivery_date']}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.blue;
      case 'PROCESSING':
        return Colors.orange;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showNotifications() {
    // Show notifications dialog
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
                    Icons.shopping_cart,
                    color: AppTheme.lightTheme.primaryColor,
                  ),
                  title: 'New order received',
                  subtitle: 'Order ORD-20240101-001',
                  trailing: Text(
                    '2 hours ago',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  onTap: () => Navigator.pushNamed(context, '/orders'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.message,
                    color: Colors.blue,
                  ),
                  title: 'Inquiry about your products',
                  subtitle: 'Bell Peppers inquiry',
                  trailing: Text(
                    '3 hours ago',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  onTap: () => Navigator.pushNamed(context, '/inquiries'),
                ),
                ListTile(
                  leading: Icon(
                    StarIcon(Icons.star_border, color: Colors.amber),
                  color: Colors.amber,
                ),
                title: 'You received a 5-star review',
                  subtitle: 'For Organic Tomatoes',
                  trailing: Text(
                    'Yesterday',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  onTap: () => Navigator.pushNamed(context, '/reviews'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  _apiService.currentUser?.profilePicture ?? '',
                ),
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.person,
                  color: Colors.grey[600],
                ),
              ),
              title: Text(
                _apiService.currentUser?.fullName ?? 'User',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              subtitle: Text(
                _apiService.currentUser?.role?.displayName ?? 'Farmer',
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

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 30.h,
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
              'Quick Actions',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 2.h,
              crossAxisSpacing: 2.w,
              childAspectRatio: 1.2,
              children: [
                _buildQuickAction(
                  'Create\nListing',
                  Icons.add_business,
                  Colors.green,
                  () => _navigateToCreateListing(),
                ),
                _buildQuickAction(
                  'View\nOrders',
                  Icons.list_alt,
                  Colors.blue,
                  () => _navigateToOrders(),
                ),
                _buildQuickAction(
                  'Manage\nProducts',
                  'inventory_2',
                  Colors.orange,
                  () => _navigateToProducts(),
                ),
                _buildQuickAction(
                  'Market\nPrices',
                  'trending_up',
                  Colors.purple,
                  () => _navigateToMarketPrices(),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 6.w,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _navigateToCreateListing() {
    Navigator.pushNamed(context, '/listings/create');
  }

  void _navigateToOrders() {
    Navigator.pushNamed(context, '/orders');
  }

  void _navigateToProducts() {
    Navigator.pushNamed(context, '/products');
  }

  void _navigateToMarketPrices() {
    Navigator.pushNamed(context, '/market-prices');
  }

  @override
  void dispose() {
    super.dispose();
  }
}