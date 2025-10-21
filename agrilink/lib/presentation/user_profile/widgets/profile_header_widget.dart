import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onEditProfile;
  final VoidCallback onCameraPressed;

  const ProfileHeaderWidget({
    Key? key,
    required this.userData,
    required this.onEditProfile,
    required this.onCameraPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.lightTheme.primaryColor,
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 2.h),
          _buildProfileImage(),
          SizedBox(height: 2.h),
          _buildUserInfo(),
          SizedBox(height: 2.h),
          _buildStatsSection(),
          SizedBox(height: 2.h),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 25.w,
          height: 25.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
          ),
          child: ClipOval(
            child: CustomImageWidget(
              imageUrl: userData["profileImage"] as String? ??
                  "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face",
              width: 25.w,
              height: 25.w,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onCameraPressed,
            child: Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: CustomIconWidget(
                iconName: 'camera_alt',
                color: Colors.white,
                size: 4.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                userData["name"] as String? ?? "John Farmer",
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (userData["isVerified"] == true) ...[
              SizedBox(width: 2.w),
              CustomIconWidget(
                iconName: 'verified',
                color: AppTheme.getSuccessColor(true),
                size: 5.w,
              ),
            ],
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            userData["role"] as String? ?? "Farmer",
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'location_on',
              color: Colors.white.withValues(alpha: 0.8),
              size: 4.w,
            ),
            SizedBox(width: 1.w),
            Flexible(
              child: Text(
                userData["location"] as String? ?? "Nairobi, Kenya",
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final List<Map<String, dynamic>> stats = [
      {
        "label": "Products",
        "value": userData["productsCount"]?.toString() ?? "24",
        "icon": "inventory",
      },
      {
        "label": "Sales",
        "value": userData["salesCount"]?.toString() ?? "156",
        "icon": "trending_up",
      },
      {
        "label": "Followers",
        "value": userData["followersCount"]?.toString() ?? "1.2K",
        "icon": "people",
      },
      {
        "label": "Rating",
        "value": userData["rating"]?.toString() ?? "4.8",
        "icon": "star",
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stats.map((stat) => _buildStatItem(stat)).toList(),
    );
  }

  Widget _buildStatItem(Map<String, dynamic> stat) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: stat["icon"] as String,
          color: Colors.white,
          size: 6.w,
        ),
        SizedBox(height: 0.5.h),
        Text(
          stat["value"] as String,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          stat["label"] as String,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onEditProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.lightTheme.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              "Edit Profile",
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Container(
          width: 12.w,
          height: 6.h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: IconButton(
            onPressed: () {
              // Share profile functionality
            },
            icon: CustomIconWidget(
              iconName: 'share',
              color: Colors.white,
              size: 5.w,
            ),
          ),
        ),
      ],
    );
  }
}
