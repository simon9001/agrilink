import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_wrapper_widget.dart';
import './widgets/camera_screen_widget.dart';
import './widgets/create_post_fab_widget.dart';
import './widgets/post_item_widget.dart';
import './widgets/story_item_widget.dart';
import './widgets/story_viewer_widget.dart';

class SocialFeed extends StatefulWidget {
  const SocialFeed({Key? key}) : super(key: key);

  @override
  State<SocialFeed> createState() => _SocialFeedState();
}

class _SocialFeedState extends State<SocialFeed> {
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;
  bool _showAppBar = true;
  double _lastScrollOffset = 0;

  // Mock data for stories
  final List<Map<String, dynamic>> _stories = [
    {
      'name': 'Add Story',
      'avatar':
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop&crop=face',
      'isAddStory': 'true'
    },
    {
      'name': 'Emma Wilson',
      'avatar':
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face',
      'isAddStory': 'false'
    },
    {
      'id': '1',
      'username': 'john_farmer',
      'profileImage':
          'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=400',
      'timeAgo': '2h ago',
      'stories': [
        {
          'imageUrl':
              'https://images.pexels.com/photos/1595104/pexels-photo-1595104.jpeg?auto=compress&cs=tinysrgb&w=800',
          'caption': 'Fresh harvest from my organic farm! 🌾',
        },
        {
          'imageUrl':
              'https://images.pexels.com/photos/1459339/pexels-photo-1459339.jpeg?auto=compress&cs=tinysrgb&w=800',
          'caption': 'Early morning in the fields',
        },
      ],
    },
    {
      'id': '2',
      'username': 'maria_crops',
      'profileImage':
          'https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=400',
      'timeAgo': '4h ago',
      'stories': [
        {
          'imageUrl':
              'https://images.pexels.com/photos/1300972/pexels-photo-1300972.jpeg?auto=compress&cs=tinysrgb&w=800',
          'caption': 'Tomato season is here! 🍅',
        },
      ],
    },
    {
      'id': '3',
      'username': 'david_livestock',
      'profileImage':
          'https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=400',
      'timeAgo': '6h ago',
      'stories': [
        {
          'imageUrl':
              'https://images.pexels.com/photos/422218/pexels-photo-422218.jpeg?auto=compress&cs=tinysrgb&w=800',
          'caption': 'Happy cows, happy farmer! 🐄',
        },
      ],
    },
  ];

  // Mock data for posts
  final List<Map<String, dynamic>> _posts = [
    {
      'userName': 'Sarah Johnson',
      'userAvatar':
          'https://images.unsplash.com/photo-1494790108755-2616b39d4baf?w=100&h=100&fit=crop',
      'timeAgo': '2 hours ago',
      'content':
          'Just harvested the most amazing organic tomatoes from our greenhouse! The weather has been perfect for growing this season. 🍅🌱',
      'image':
          'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=500&h=400&fit=crop',
      'likes': 127,
      'comments': 23,
      'shares': 8,
      'isLiked': false,
    },
    {
      'id': '1',
      'username': 'sarah_organic',
      'profileImage':
          'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400',
      'isVerified': true,
      'location': 'Green Valley Farm, CA',
      'imageUrl':
          'https://images.pexels.com/photos/1300972/pexels-photo-1300972.jpeg?auto=compress&cs=tinysrgb&w=800',
      'caption':
          'Just harvested these beautiful organic tomatoes! 🍅 Nothing beats the taste of homegrown produce. Available for sale at our farm stand. #OrganicFarming #FreshProduce #TomatoHarvest',
      'likesCount': 127,
      'commentsCount': 23,
      'isLiked': false,
      'isFollowing': false,
      'timeAgo': '2 hours ago',
      'linkedProduct': {
        'name': 'Organic Tomatoes',
        'price': '\$4.99/lb',
      },
    },
    {
      'id': '2',
      'username': 'mike_dairy',
      'profileImage':
          'https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=400',
      'isVerified': true,
      'location': 'Sunshine Dairy Farm, TX',
      'imageUrl':
          'https://images.pexels.com/photos/422218/pexels-photo-422218.jpeg?auto=compress&cs=tinysrgb&w=800',
      'caption':
          'Our Holstein cows are enjoying the beautiful weather today! 🐄 Fresh milk delivery available within 50 miles. Contact us for premium dairy products. #DairyFarm #FreshMilk #HappyCows',
      'likesCount': 89,
      'commentsCount': 15,
      'isLiked': true,
      'isFollowing': true,
      'timeAgo': '4 hours ago',
      'linkedProduct': {
        'name': 'Fresh Milk',
        'price': '\$3.50/gallon',
      },
    },
    {
      'id': '3',
      'username': 'anna_grains',
      'profileImage':
          'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=400',
      'isVerified': false,
      'location': 'Golden Fields, IA',
      'imageUrl':
          'https://images.pexels.com/photos/1595104/pexels-photo-1595104.jpeg?auto=compress&cs=tinysrgb&w=800',
      'caption':
          'Wheat harvest season is in full swing! 🌾 This year\'s crop is looking exceptional. Bulk orders welcome for local bakeries and food processors. #WheatHarvest #GrainFarming #BulkSales',
      'likesCount': 156,
      'commentsCount': 31,
      'isLiked': false,
      'isFollowing': false,
      'timeAgo': '6 hours ago',
      'linkedProduct': null,
    },
    {
      'id': '4',
      'username': 'carlos_vegetables',
      'profileImage':
          'https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=400',
      'isVerified': true,
      'location': 'Valley Fresh Farms, FL',
      'imageUrl':
          'https://images.pexels.com/photos/1459339/pexels-photo-1459339.jpeg?auto=compress&cs=tinysrgb&w=800',
      'caption':
          'Early morning harvest of our bell peppers and cucumbers! 🫑🥒 Farm-to-table freshness guaranteed. Now accepting orders for restaurants and grocery stores. #VegetableFarm #FarmToTable #FreshVeggies',
      'likesCount': 203,
      'commentsCount': 42,
      'isLiked': true,
      'isFollowing': false,
      'timeAgo': '8 hours ago',
      'linkedProduct': {
        'name': 'Mixed Vegetables',
        'price': '\$2.99/lb',
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset > _lastScrollOffset &&
        _scrollController.offset > 100) {
      // Scrolling down
      if (_showAppBar) {
        setState(() {
          _showAppBar = false;
        });
      }
    } else {
      // Scrolling up
      if (!_showAppBar) {
        setState(() {
          _showAppBar = true;
        });
      }
    }
    _lastScrollOffset = _scrollController.offset;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 0:
        // Already on feed
        break;
      case 1:
        // Navigate to search or explore
        break;
      case 2:
        // Open create post
        _showCreatePostModal();
        break;
      case 3:
        // Navigate to notifications
        break;
      case 4:
        // Navigate to profile
        Navigator.pushNamed(context, AppRoutes.userProfile);
        break;
    }
  }

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostFabWidget(
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handleLogout() {
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
              await AuthService.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthWrapperWidget(
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: _showAppBar ? _buildAppBar() : null,
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.grey.withAlpha(26),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: null,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Text(
            'AgriLink',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.lightTheme.primaryColor,
            ),
          ),
          const Spacer(),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Handle messages
          },
          icon: const Icon(
            Icons.message_outlined,
            color: Colors.black87,
          ),
        ),
        PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.black87),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout();
            }
          },
        ),
        SizedBox(width: 2.w),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshFeed,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Stories section
          SliverToBoxAdapter(
            child: _buildStoriesSection(),
          ),

          // Posts section
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _posts.length) {
                  return PostItemWidget(
                    post: _posts[index],
                    onLike: () => _toggleLike(index),
                    onComment: () => _showCommentsSheet(index),
                    onShare: () => _sharePost(index),
                    onFollow: () => _toggleFollow(index),
                  );
                }
                return null;
              },
              childCount: _posts.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Stories',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            height: 12.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: 3.w),
                  child: StoryItemWidget(
                    story: _stories[index],
                    onTap: () => _viewStory(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.lightTheme.primaryColor,
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _refreshFeed() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    // Refresh posts data here
  }

  void _toggleLike(int index) {
    setState(() {
      _posts[index]['isLiked'] = !_posts[index]['isLiked'];
      if (_posts[index]['isLiked']) {
        _posts[index]['likesCount']++;
      } else {
        _posts[index]['likesCount']--;
      }
    });
  }

  void _toggleFollow(int index) {
    setState(() {
      _posts[index]['isFollowing'] = !_posts[index]['isFollowing'];
    });
  }

  void _showCommentsSheet(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Text(
                    'Comments',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${_posts[index]['commentsCount']} comments',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            Expanded(
              child: Center(
                child: Text(
                  'Comments will be implemented here',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost(int index) {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewStory(int index) {
    if (_stories[index]['isAddStory'] == 'true') {
      // Open camera to add story
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreenWidget(
            onImageCaptured: (XFile image) {
              // Handle captured image
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else {
      // View existing story
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryViewerWidget(
            stories: _stories,
            initialIndex:
                index - 1, // Subtract 1 because first item is "Add Story"
            onComplete: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }
}