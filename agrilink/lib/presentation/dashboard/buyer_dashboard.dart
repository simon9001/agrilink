import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../services/django_api_service.dart';
import '../../core/user_role.dart';
import '../dashboard/widgets/dashboard_stats_widget.dart';
import '../dashboard/widgets/recent_activities_widget.dart';
import '../dashboard/widgets/quick_actions_widget.dart';
import '../dashboard/widgets/search_filters_widget.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({Key? key}) : super(key: key);

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerState extends State<BuyerDashboard> {
  final DjangoApiService _apiService = DjangoApiService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  // Mock data for development
  final Map<String, dynamic> _mockDashboardData = {
    'stats': {
      'total_orders': 45,
      'active_orders': 8,
      'completed_orders': 37,
      'total_spent': '\$8,750',
      'monthly_savings': '\$1,250',
      'favorite_farmers': 12,
      'saved_searches': 6,
      'cart_items': 3,
    },
    'recent_orders': [
      {
        'id': '1',
        'order_number': 'ORD-20240101-001',
        'farmer_name': 'Green Valley Farm',
        'product_name': 'Organic Tomatoes',
        'quantity': '100 kg',
        'total_amount': '\$399.00',
        'status': 'DELIVERED',
        'created_at': '2024-01-01T10:30:00Z',
        'delivery_date': '2024-01-03',
        'rating': 5.0,
      },
      {
        'id': '2',
        'order_number': 'ORD-20240102-002',
        'farmer_name': 'Sunshine Farms',
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
        'order_number': 'ORD-20240103-003',
        'farmer_name': 'Golden Fields',
        'product_name': 'Fresh Lettuce',
        'quantity': '150 kg',
        'total_amount': '\$373.50',
        'status': 'CONFIRMED',
        'created_at': '2024-01-03T09:45:00Z',
        'delivery_date': '2024-01-06',
        'rating': 4.9,
      },
    ],
    'recommended_products': [
      {
        'id': '1',
        'product_name': 'Premium Organic Tomatoes',
        'farmer': 'Green Valley Farm',
        'price': '\$4.99/kg',
        'rating': 4.8,
        'image': 'https://images.pexels.com/photos/1300972/pexels-photo-1300972.jpeg?auto=compress&cs=tinysrgb&w=400',
        'location': 'Nairobi, Kenya',
        'is_organic': true,
        'certification': 'Organic Certified',
      },
      {
        'id': '2',
        'product_name': 'Fresh Bell Peppers',
        'farmer': 'Sunshine Farms',
        'price': '\$4.99/kg',
        'rating': 4.7,
        'image': 'https://images.unsplash.com/photo-1441997556409-4ae437439a2e?auto=conmpress&cs=tinysrgb&w=400',
        'location': 'Nakuru, Kenya',
        'is_organic': true,
        'certification': 'GlobalG.A.P.',
      },
      {
        'id': '3',
        'product_name': 'High-Quality Maize',
        'farmer': 'Golden Fields',
        'price': '\$0.45/kg',
        'rating': 4.6,
        'image': 'https://images.pexels.com/photos/1595104/pexels-photo-1595104.jpeg?auto=conmpress&cs=tinysrgb&w=400',
        'location': 'Eldoret, Kenya',
        'certification': 'Quality Assured',
      },
    ],
    'search_history': [
      {
        'query': 'organic tomatoes nairobi',
        'timestamp': '2 hours ago',
        'filters': {
          'category': 'FRUITS',
          'price_range': '3.0-5.0',
          'location': 'nairobi',
          'organic_only': true,
        },
      },
      {
        'query': 'fresh vegetables',
        'timestamp': '1 day ago',
        'filters': {
          'category': 'VEGETABLES',
          'location': 'kenya',
          'radius': '50km',
        },
      },
      {
        'query': 'maize price trends',
        'timestamp': '3 days ago',
        'filters': {
          'category': 'GRAINS',
          'time_period': 'monthly',
        },
      },
    ],
    'recent_activities': [
      {
        'id': '1',
        'type': 'order',
        'message': 'Order delivered successfully from Green Valley Farm',
        'timestamp': '1 hour ago',
        'icon': 'check_circle',
        'priority': 'high',
      },
      {
        'id': '2',
        'type': 'saved_search',
        'message': 'Saved search for organic tomatoes',
        'timestamp': '2 hours ago',
        'icon': 'bookmark',
        'priority': 'medium',
      },
      {
        'id': '3',
        'type': 'review',
        'message': 'You left a 5-star review for Green Valley Farm',
        'timestamp': '1 day ago',
        'icon': 'star',
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
      final data = await _apiService.getDashboardData(role: UserRole.BUYER);
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
        onPressed: _showSearchFilters,
        child: CustomIconWidget(
          iconName: 'search',
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
        'Buyer Dashboard',
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

          // Search Filters
          _buildSectionTitle('Browse Products'),
          SizedBox(height: 1.h),
          SearchFiltersWidget(
            onSearch: _performSearch,
            onFilterChange: _updateFilters,
          ),
          SizedBox(height: 2.h),

          // Recommended Products
          _buildSectionTitle('Recommended for You'),
          SizedBox(height: 1.h),
          _buildRecommendedProducts(),
          SizedBox(height: 3.h),

          // Recent Orders
          _buildSectionTitle('Recent Orders'),
          SizedBox(height: 1.h),
          _buildRecentOrders(),
          SizedBox(height: 3.h),

          // Search History
          _buildSectionTitle('Search History'),
          SizedBox(height: 1.h),
          _buildSearchHistory(),
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
            onCreateOrder: _navigateToCreateOrder,
            onViewOrders: _navigateToOrders,
            onViewFavorites: _navigateToFavorites,
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

  Widget _buildRecommendedProducts() {
    final products = _dashboardData!['recommended_products'] as List<Map<String, dynamic>>;

    return Container(
      height: 22.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _buildProductCard(products[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
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
                image: NetworkImage(product['image'] as String),
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
                  product['product_name'] as String,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'by ${product['farmer']}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getRatingColor(product['rating'] as double),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            size: 3.w,
                            color: Colors.white,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '${product['rating']}',
                            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: product['is_organic'] ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product['is_organic'] ? 'Organic' : 'Conventional',
                        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${product['certification']}',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  '${product['price']} per kg',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Location: ${product['location']}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) {
      return Colors.green;
    } else if (rating >= 3.5) {
      return Colors.amber;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildSearchHistory() {
    final searches = _dashboardData!['search_history'] as List<Map<String, dynamic>>;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: searches.length,
      itemBuilder: (context, index) {
        return _buildSearchHistoryItem(searches[index]);
      },
    );
  }

  Widget _buildSearchHistoryItem(Map<String, dynamic> search) {
    return ListTile(
      leading: Icon(
        Icons.history,
        color: Colors.grey[600],
      ),
      title: search['query'] as String,
      subtitle: _formatSearchTime(search['timestamp'] as String),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey[600],
      ),
      onTap: () {
        _performSearch(search['query'] as String);
      },
    );
  }

  String _formatSearchTime(String timestamp) {
    final DateTime time = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${difference.inDays} days ago';
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
              'Seller: ${order['farmer_name']}',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Product: ${order['product_name']} (${order['quantity']})',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.message_outlined, color: Colors.blue),
                  onPressed: () => _showOrderChat(order),
                ),
                IconButton(
                  icon: Icon(Icons.rate_review, color: Colors.amber),
                  onPressed: () => _showReviewDialog(order),
                ),
                SizedBox(width: 1.w),
              ],
            ),
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

  void _showOrderChat(Map<String, dynamic> order) {
    // Open chat with farmer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat feature coming soon!'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> order) {
    // Show review dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How was your experience with this order?',
              style: AppTheme.lightTheme.textTheme.bodyLarge,
            ),
            SizedBox(height: 2.h),
            // Add star rating widget here
            Text(
              'Rating functionality coming soon!',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Submit Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.primaryColor,
            ),
          ),
        ],
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
                    Icons.shopping_cart,
                    color: Colors.blue,
                  ),
                  title: 'Order #ORD-20240101-001 delivered',
                  subtitle: 'Mark as delivered successfully',
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                  onTap: () => Navigator.pushNamed(context, '/orders/1'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.favorite_border,
                    color: Colors.red,
                  ),
                  title: 'Price drop alert for your saved search',
                  subtitle: 'Tomato prices dropped 15%',
                  trailing: Icon(Icons.trending_up, color: Colors.orange),
                  onTap: () => Navigator.pushNamed(context, '/market-prices')),
                ),
                ListTile(
                  leading: Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  title: 'You received a 5-star review!',
                  subtitle: 'For Organic Tomatoes from Green Valley Farm',
                  trailing: Icon(Icons.star, color: Colors.amber),
                  onTap: () => Navigator.pushNamed(context, '/reviews')),
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

  void _showSearchFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 60.h,
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
              'Search Filters',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: [
                  _buildFilterSection('Category', [
                    'All', 'Fruits', 'Vegetables', 'Grains', 'Livestock', 'Dairy'],
                    selected: 'All',
                  ),
                  _buildFilterSection('Price Range', [
                    'All', '\$0-50', '\$50-100', '\$100-500', '\$500+',
                  ]),
                  _buildFilterSection('Quality Grade', [
                    'All', 'Grade A', 'Grade B', 'Grade C',
                  ]),
                  _buildFilterSection('Location', [
                    'All', 'Within 50km', 'Within 100km', 'Within 200km',
                  ]),
                  _buildFilterSection('Certification', [
                    'All', 'Organic', 'GAP', 'None',
                  ]),
                  _buildFilterSection('Farmer Rating', [
                    'All', '4+ stars', '3+ stars', '2+ stars',
                  ]),
                ],
                SizedBox(height: 2.h),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      child: Text('Apply Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearFilters();
                      },
                      child: Text('Clear Filters'),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 1.w,
          runSpacing: 1.w,
          children: options.map((option) => _buildFilterChip(
            option,
            title: option,
            isSelected: option == options.first,
            onTap: () {
              Navigator.pop(context);
              // Handle filter selection
            },
          )),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String title, String value, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: title,
      selected: isSelected,
      onSelected: () => onTap(),
      onDeleted: () {
        Navigator.pop(context);
      },
      labelStyle: TextButton.styleFromSide(
        backgroundColor: isSelected
            ? AppTheme.lightTheme.primaryColor
            : Colors.grey[300],
        ),
      );
  }

  void _applyFilters() {
    // Apply selected filters and refresh listings
    Navigator.pop(context);
    _loadDashboardData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Filters applied successfully',
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearFilters() {
    // Clear all filters and refresh listings
    Navigator.pop(context);
    _loadDashboardData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Filters cleared',
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _performSearch(String query) {
    Navigator.pop(context);
    // Navigate to search results page with query
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Searching for: $query',
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToCreateOrder() {
    Navigator.pushNamed(context, '/orders/create');
  }

  void _navigateToOrders() {
    Navigator.pushNamed(context, '/orders');
  }

  void _navigateToFavorites() {
    Navigator.pushNamed(context, '/favorites');
  }

  @override
  void dispose() {
    super.dispose();
  }
}