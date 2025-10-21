import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PostItemWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onFollow;

  const PostItemWidget({
    Key? key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onFollow,
  }) : super(key: key);

  @override
  State<PostItemWidget> createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showHeartAnimation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    setState(() {
      _showHeartAnimation = true;
    });
    _animationController.forward().then((_) {
      _animationController.reverse().then((_) {
        setState(() {
          _showHeartAnimation = false;
        });
      });
    });
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLiked = widget.post['isLiked'] as bool;
    final int likesCount = widget.post['likesCount'] as int;
    final int commentsCount = widget.post['commentsCount'] as int;
    final bool isFollowing = widget.post['isFollowing'] as bool;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with profile info
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.lightTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: widget.post['profileImage'] as String,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.post['username'] as String,
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.post['isVerified'] as bool) ...[
                            SizedBox(width: 1.w),
                            CustomIconWidget(
                              iconName: 'verified',
                              color: AppTheme.lightTheme.primaryColor,
                              size: 4.w,
                            ),
                          ],
                        ],
                      ),
                      if (widget.post['location'] != null) ...[
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'location_on',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 3.w,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              widget.post['location'] as String,
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isFollowing)
                  TextButton(
                    onPressed: widget.onFollow,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.primaryColor,
                      foregroundColor:
                          AppTheme.lightTheme.colorScheme.onPrimary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                    ),
                    child: Text(
                      'Follow',
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(width: 2.w),
                CustomIconWidget(
                  iconName: 'more_vert',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 6.w,
                ),
              ],
            ),
          ),

          // Post image with double tap for like
          GestureDetector(
            onDoubleTap: _handleDoubleTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: CustomImageWidget(
                    imageUrl: widget.post['imageUrl'] as String,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (_showHeartAnimation)
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: CustomIconWidget(
                          iconName: 'favorite',
                          color: Colors.white,
                          size: 20.w,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onLike,
                      child: CustomIconWidget(
                        iconName: isLiked ? 'favorite' : 'favorite_border',
                        color: isLiked
                            ? Colors.red
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 7.w,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    GestureDetector(
                      onTap: widget.onComment,
                      child: CustomIconWidget(
                        iconName: 'chat_bubble_outline',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 7.w,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    GestureDetector(
                      onTap: widget.onShare,
                      child: CustomIconWidget(
                        iconName: 'share',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 7.w,
                      ),
                    ),
                    const Spacer(),
                    if (widget.post['linkedProduct'] != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2.w),
                          border: Border.all(
                            color: AppTheme.lightTheme.primaryColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'shopping_bag',
                              color: AppTheme.lightTheme.primaryColor,
                              size: 4.w,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Shop',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Likes count
                if (likesCount > 0)
                  Text(
                    '$likesCount ${likesCount == 1 ? 'like' : 'likes'}',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                SizedBox(height: 1.h),

                // Caption
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${widget.post['username']} ',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: widget.post['caption'] as String,
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 1.h),

                // Comments count
                if (commentsCount > 0)
                  GestureDetector(
                    onTap: widget.onComment,
                    child: Text(
                      'View all $commentsCount comments',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                SizedBox(height: 1.h),

                // Time ago
                Text(
                  widget.post['timeAgo'] as String,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
