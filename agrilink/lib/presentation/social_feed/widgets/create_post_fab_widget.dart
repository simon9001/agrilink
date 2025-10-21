import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CreatePostFabWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const CreatePostFabWidget({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppTheme.lightTheme.primaryColor,
      foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
      elevation: 4.0,
      icon: CustomIconWidget(
        iconName: 'camera_alt',
        color: AppTheme.lightTheme.colorScheme.onPrimary,
        size: 6.w,
      ),
      label: Text(
        'Create Post',
        style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.w),
      ),
    );
  }
}
