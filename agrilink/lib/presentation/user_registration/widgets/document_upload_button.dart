import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class DocumentUploadButton extends StatelessWidget {
  final String label;
  final String? fileName;
  final VoidCallback onTap;
  final bool isRequired;

  const DocumentUploadButton({
    Key? key,
    required this.label,
    this.fileName,
    required this.onTap,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        SizedBox(height: 1.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: hasFile
                  ? AppTheme.getSuccessColor(true).withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.surface,
              border: Border.all(
                color: hasFile
                    ? AppTheme.getSuccessColor(true)
                    : AppTheme.lightTheme.colorScheme.outline,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: hasFile ? 'check_circle' : 'upload_file',
                  color: hasFile
                      ? AppTheme.getSuccessColor(true)
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasFile ? 'Document Uploaded' : 'Upload Document',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          color: hasFile
                              ? AppTheme.getSuccessColor(true)
                              : AppTheme.lightTheme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hasFile) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          fileName!,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          'PDF, DOC, or image files accepted',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                CustomIconWidget(
                  iconName: 'arrow_forward_ios',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 4.w,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
