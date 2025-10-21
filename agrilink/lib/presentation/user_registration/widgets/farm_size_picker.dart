import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class FarmSizePicker extends StatelessWidget {
  final String selectedSize;
  final Function(String) onSizeSelected;

  const FarmSizePicker({
    Key? key,
    required this.selectedSize,
    required this.onSizeSelected,
  }) : super(key: key);

  static const List<Map<String, String>> farmSizes = [
    {
      'value': 'small',
      'label': 'Small (< 2 acres)',
      'description': 'Subsistence farming'
    },
    {
      'value': 'medium',
      'label': 'Medium (2-10 acres)',
      'description': 'Commercial farming'
    },
    {
      'value': 'large',
      'label': 'Large (10+ acres)',
      'description': 'Large-scale farming'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farm Size',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        ...farmSizes.map((size) {
          final isSelected = selectedSize == size['value'];
          return GestureDetector(
            onTap: () => onSizeSelected(size['value']!),
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1)
                    : AppTheme.lightTheme.colorScheme.surface,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 5.w,
                    height: 5.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.outline,
                        width: 2.0,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 2.5.w,
                              height: 2.5.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.lightTheme.colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          size['label']!,
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          size['description']!,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
