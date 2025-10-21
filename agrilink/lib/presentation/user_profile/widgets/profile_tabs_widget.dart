import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileTabsWidget extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileTabsWidget({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<ProfileTabsWidget> createState() => _ProfileTabsWidgetState();
}

class _ProfileTabsWidgetState extends State<ProfileTabsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "About"),
              Tab(text: "Products"),
              Tab(text: "Reviews"),
            ],
          ),
        ),
        SizedBox(
          height: 60.h,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAboutTab(),
              _buildProductsTab(),
              _buildReviewsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutSection(
              "Bio",
              widget.userData["bio"] as String? ??
                  "Passionate organic farmer with 10+ years of experience in sustainable agriculture. Specializing in crop rotation and natural pest management."),
          SizedBox(height: 3.h),
          _buildAboutSection("Farm Details", null),
          SizedBox(height: 1.h),
          _buildFarmDetails(),
          SizedBox(height: 3.h),
          _buildAboutSection("Specializations", null),
          SizedBox(height: 1.h),
          _buildSpecializations(),
          SizedBox(height: 3.h),
          _buildAboutSection("Achievements", null),
          SizedBox(height: 1.h),
          _buildAchievements(),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String title, String? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (content != null) ...[
          SizedBox(height: 1.h),
          Text(
            content,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildFarmDetails() {
    final List<Map<String, dynamic>> farmDetails = [
      {"label": "Farm Size", "value": "25 acres", "icon": "landscape"},
      {
        "label": "Livestock",
        "value": "50 cattle, 200 chickens",
        "icon": "pets"
      },
      {"label": "Main Crops", "value": "Maize, Beans, Tomatoes", "icon": "eco"},
      {"label": "Farming Method", "value": "Organic", "icon": "nature"},
    ];

    return Column(
      children: farmDetails
          .map((detail) => Container(
                margin: EdgeInsets.only(bottom: 2.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: detail["icon"] as String,
                        color: AppTheme.lightTheme.primaryColor,
                        size: 5.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail["label"] as String,
                            style: AppTheme.lightTheme.textTheme.labelMedium
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            detail["value"] as String,
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSpecializations() {
    final List<String> specializations = [
      "Organic Farming",
      "Crop Rotation",
      "Sustainable Agriculture",
      "Pest Management",
      "Soil Conservation",
    ];

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: specializations
          .map((spec) => Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  spec,
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildAchievements() {
    final List<Map<String, dynamic>> achievements = [
      {"title": "Best Organic Farmer 2023", "icon": "emoji_events"},
      {"title": "Sustainable Agriculture Award", "icon": "eco"},
      {"title": "Community Leader", "icon": "people"},
    ];

    return Column(
      children: achievements
          .map((achievement) => Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.getSuccessColor(true).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        AppTheme.getSuccessColor(true).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: achievement["icon"] as String,
                      color: AppTheme.getSuccessColor(true),
                      size: 5.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        achievement["title"] as String,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildProductsTab() {
    final List<Map<String, dynamic>> products = [
      {
        "id": 1,
        "name": "Organic Tomatoes",
        "price": "\$5.99/kg",
        "image":
            "https://images.unsplash.com/photo-1546470427-e26264be0b0d?w=400&h=400&fit=crop",
        "status": "Available",
        "stock": "50 kg",
      },
      {
        "id": 2,
        "name": "Fresh Maize",
        "price": "\$3.50/kg",
        "image":
            "https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=400&h=400&fit=crop",
        "status": "Available",
        "stock": "200 kg",
      },
      {
        "id": 3,
        "name": "Organic Beans",
        "price": "\$4.25/kg",
        "image":
            "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&h=400&fit=crop",
        "status": "Low Stock",
        "stock": "15 kg",
      },
      {
        "id": 4,
        "name": "Free Range Eggs",
        "price": "\$0.50/piece",
        "image":
            "https://images.unsplash.com/photo-1518569656558-1f25e69d93d7?w=400&h=400&fit=crop",
        "status": "Available",
        "stock": "100 pieces",
      },
    ];

    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 3.w,
        childAspectRatio: 0.8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
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
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CustomImageWidget(
                    imageUrl: product["image"] as String,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(2.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product["name"] as String,
                        style: AppTheme.lightTheme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        product["price"] as String,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: product["status"] == "Available"
                                  ? AppTheme.getSuccessColor(true)
                                      .withValues(alpha: 0.1)
                                  : AppTheme.getWarningColor(true)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product["status"] as String,
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: product["status"] == "Available"
                                    ? AppTheme.getSuccessColor(true)
                                    : AppTheme.getWarningColor(true),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            product["stock"] as String,
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    final List<Map<String, dynamic>> reviews = [
      {
        "id": 1,
        "customerName": "Sarah Johnson",
        "customerImage":
            "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop&crop=face",
        "rating": 5,
        "comment":
            "Excellent quality organic tomatoes! Fresh and tasty. Will definitely order again.",
        "date": "2 days ago",
        "productName": "Organic Tomatoes",
      },
      {
        "id": 2,
        "customerName": "Michael Chen",
        "customerImage":
            "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face",
        "rating": 4,
        "comment":
            "Good quality maize, delivered on time. Packaging could be better but overall satisfied.",
        "date": "1 week ago",
        "productName": "Fresh Maize",
      },
      {
        "id": 3,
        "customerName": "Emma Wilson",
        "customerImage":
            "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face",
        "rating": 5,
        "comment":
            "Amazing farmer! Very professional and the beans were of exceptional quality.",
        "date": "2 weeks ago",
        "productName": "Organic Beans",
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Container(
          margin: EdgeInsets.only(bottom: 3.h),
          padding: EdgeInsets.all(4.w),
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
              Row(
                children: [
                  ClipOval(
                    child: CustomImageWidget(
                      imageUrl: review["customerImage"] as String,
                      width: 12.w,
                      height: 12.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review["customerName"] as String,
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          review["date"] as String,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                        5,
                        (starIndex) => CustomIconWidget(
                              iconName: starIndex < (review["rating"] as int)
                                  ? 'star'
                                  : 'star_border',
                              color: starIndex < (review["rating"] as int)
                                  ? AppTheme.getWarningColor(true)
                                  : AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                              size: 4.w,
                            )),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                review["comment"] as String,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Product: ${review["productName"] as String}",
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
