import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/profile_header_widget.dart';
import './widgets/profile_tabs_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/social_network_widget.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  // Mock user data
  final Map<String, dynamic> userData = {
    "id": 1,
    "name": "John Farmer",
    "email": "john.farmer@agrilink.com",
    "phone": "+254712345678",
    "role": "Farmer",
    "location": "Nairobi, Kenya",
    "profileImage":
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face",
    "isVerified": true,
    "bio":
        "Passionate organic farmer with 10+ years of experience in sustainable agriculture. Specializing in crop rotation and natural pest management techniques. Committed to providing fresh, healthy produce to local communities.",
    "farmSize": "25 acres",
    "livestock": "50 cattle, 200 chickens",
    "mainCrops": "Maize, Beans, Tomatoes",
    "farmingMethod": "Organic",
    "joinDate": "January 2020",
    "productsCount": 24,
    "salesCount": 156,
    "followersCount": "1.2K",
    "followingCount": 245,
    "groupsCount": 8,
    "rating": 4.8,
    "reviewsCount": 89,
    "totalEarnings": "\$12,450",
    "subscriptionStatus": "Premium",
    "lastActive": "2 hours ago",
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showAppBarTitle) {
      setState(() {
        _showAppBarTitle = true;
      });
    } else if (_scrollController.offset <= 200 && _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                ProfileHeaderWidget(
                  userData: userData,
                  onEditProfile: _showEditProfileDialog,
                  onCameraPressed: _showImagePickerDialog,
                ),
                SizedBox(height: 2.h),
                SocialNetworkWidget(
                  userData: userData,
                  onNavigateToSocialFeed: () =>
                      _navigateToRoute('/social-feed'),
                ),
                ProfileTabsWidget(userData: userData),
                SettingsSectionWidget(
                  onNavigateToPaymentMethods: () =>
                      _navigateToRoute('/payment-methods'),
                ),
                SizedBox(height: 10.h), // Bottom padding for safe area
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionsDialog,
        child: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 6.w,
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.lightTheme.primaryColor,
      foregroundColor: Colors.white,
      title: AnimatedOpacity(
        opacity: _showAppBarTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Row(
          children: [
            ClipOval(
              child: CustomImageWidget(
                imageUrl: userData["profileImage"] as String,
                width: 8.w,
                height: 8.w,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userData["name"] as String,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    userData["role"] as String,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: _showProfileMenu,
          icon: CustomIconWidget(
            iconName: 'more_vert',
            color: Colors.white,
            size: 6.w,
          ),
        ),
      ],
    );
  }

  void _navigateToRoute(String route) {
    Navigator.pushNamed(context, route);
  }

  void _showEditProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Profile",
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 6.w,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    _buildEditField("Full Name", userData["name"] as String),
                    SizedBox(height: 2.h),
                    _buildEditField("Email", userData["email"] as String),
                    SizedBox(height: 2.h),
                    _buildEditField("Phone", userData["phone"] as String),
                    SizedBox(height: 2.h),
                    _buildEditField("Location", userData["location"] as String),
                    SizedBox(height: 2.h),
                    _buildEditField("Bio", userData["bio"] as String,
                        maxLines: 4),
                    SizedBox(height: 2.h),
                    _buildEditField(
                        "Farm Size", userData["farmSize"] as String),
                    SizedBox(height: 2.h),
                    _buildEditField(
                        "Main Crops", userData["mainCrops"] as String),
                    SizedBox(height: 4.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSuccessMessage("Profile updated successfully!");
                        },
                        child: Text("Save Changes"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, String value, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          initialValue: value,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: "Enter $label",
          ),
        ),
      ],
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              "Update Profile Photo",
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImagePickerOption(
                  "Camera",
                  "camera_alt",
                  () {
                    Navigator.pop(context);
                    _showSuccessMessage("Photo captured successfully!");
                  },
                ),
                _buildImagePickerOption(
                  "Gallery",
                  "photo_library",
                  () {
                    Navigator.pop(context);
                    _showSuccessMessage("Photo selected successfully!");
                  },
                ),
                _buildImagePickerOption(
                  "Remove",
                  "delete",
                  () {
                    Navigator.pop(context);
                    _showSuccessMessage("Profile photo removed!");
                  },
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerOption(
      String label, String icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.primaryColor,
              size: 7.w,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  void _showQuickActionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              "Quick Actions",
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 1.2,
              children: [
                _buildQuickAction("Add Product", "add_box", () {}),
                _buildQuickAction("Share Profile", "share", () {}),
                _buildQuickAction("QR Code", "qr_code", () {}),
                _buildQuickAction("Invite Friends", "person_add", () {}),
                _buildQuickAction("Analytics", "analytics", () {}),
                _buildQuickAction("Support", "help", () {}),
              ],
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, String icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.primaryColor,
              size: 6.w,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'bookmark',
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              title: Text("Saved Items"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'history',
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              title: Text("Activity History"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'logout',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 6.w,
              ),
              title: Text(
                "Logout",
                style: TextStyle(color: AppTheme.lightTheme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation();
              },
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
        title: Text("Logout"),
        content: Text("Are you sure you want to logout from AgriLink?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToRoute('/splash-screen');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.getSuccessColor(true),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
