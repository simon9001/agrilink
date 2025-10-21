import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SocialNetworkWidget extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onNavigateToSocialFeed;

  const SocialNetworkWidget({
    Key? key,
    required this.userData,
    required this.onNavigateToSocialFeed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Agricultural Network",
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: onNavigateToSocialFeed,
                  child: Text(
                    "View All",
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildNetworkStats(),
          SizedBox(height: 2.h),
          _buildRecentConnections(),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildNetworkStats() {
    final List<Map<String, dynamic>> networkStats = [
      {
        "label": "Following",
        "count": userData["followingCount"]?.toString() ?? "245",
        "icon": "person_add",
        "color": AppTheme.lightTheme.primaryColor,
      },
      {
        "label": "Followers",
        "count": userData["followersCount"]?.toString() ?? "1.2K",
        "icon": "people",
        "color": AppTheme.lightTheme.colorScheme.secondary,
      },
      {
        "label": "Groups",
        "count": userData["groupsCount"]?.toString() ?? "8",
        "icon": "groups",
        "color": AppTheme.getSuccessColor(true),
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: networkStats
            .map((stat) => Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 1.w),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: (stat["color"] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (stat["color"] as Color).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        CustomIconWidget(
                          iconName: stat["icon"] as String,
                          color: stat["color"] as Color,
                          size: 6.w,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          stat["count"] as String,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: stat["color"] as Color,
                          ),
                        ),
                        Text(
                          stat["label"] as String,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildRecentConnections() {
    final List<Map<String, dynamic>> recentConnections = [
      {
        "id": 1,
        "name": "Maria Santos",
        "role": "Organic Farmer",
        "location": "Mombasa, Kenya",
        "image":
            "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop&crop=face",
        "isFollowing": true,
        "mutualConnections": 12,
      },
      {
        "id": 2,
        "name": "Dr. James Kimani",
        "role": "Veterinarian",
        "location": "Nakuru, Kenya",
        "image":
            "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=100&h=100&fit=crop&crop=face",
        "isFollowing": false,
        "mutualConnections": 8,
      },
      {
        "id": 3,
        "name": "Green Valley Supplies",
        "role": "Input Supplier",
        "location": "Nairobi, Kenya",
        "image":
            "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=100&h=100&fit=crop",
        "isFollowing": true,
        "mutualConnections": 25,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            "Recent Connections",
            style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
              color: AppTheme.lightTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          height: 20.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: recentConnections.length,
            itemBuilder: (context, index) {
              final connection = recentConnections[index];
              return Container(
                width: 40.w,
                margin: EdgeInsets.only(right: 3.w),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipOval(
                          child: CustomImageWidget(
                            imageUrl: connection["image"] as String,
                            width: 15.w,
                            height: 15.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (connection["role"] == "Veterinarian")
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 5.w,
                              height: 5.w,
                              decoration: BoxDecoration(
                                color: AppTheme.getSuccessColor(true),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: CustomIconWidget(
                                iconName: 'verified',
                                color: Colors.white,
                                size: 3.w,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      connection["name"] as String,
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      connection["role"] as String,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'location_on',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 3.w,
                        ),
                        SizedBox(width: 1.w),
                        Flexible(
                          child: Text(
                            connection["location"] as String,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle follow/unfollow
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: connection["isFollowing"] == true
                              ? AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.2)
                              : AppTheme.lightTheme.primaryColor,
                          foregroundColor: connection["isFollowing"] == true
                              ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                              : Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          connection["isFollowing"] == true
                              ? "Following"
                              : "Follow",
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
