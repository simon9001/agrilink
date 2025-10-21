import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StoryItemWidget extends StatelessWidget {
  final Map<String, dynamic> story;
  final VoidCallback onTap;

  const StoryItemWidget({
    Key? key,
    required this.story,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isAddStory = story['id'] == 'add_story';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18.w,
        margin: EdgeInsets.only(right: 3.w),
        child: Column(
          children: [
            Container(
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isAddStory
                    ? null
                    : LinearGradient(
                        colors: [
                          AppTheme.lightTheme.primaryColor,
                          AppTheme.lightTheme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: isAddStory
                    ? Border.all(
                        color: AppTheme.lightTheme.dividerColor,
                        width: 1.5,
                      )
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.all(isAddStory ? 0 : 0.5.w),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAddStory
                        ? AppTheme.lightTheme.colorScheme.surface
                        : null,
                  ),
                  child: ClipOval(
                    child: isAddStory
                        ? Container(
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'add',
                                color: AppTheme.lightTheme.primaryColor,
                                size: 6.w,
                              ),
                            ),
                          )
                        : CustomImageWidget(
                            imageUrl: story['profileImage'] as String,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              isAddStory ? 'Add Story' : (story['username'] as String),
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
