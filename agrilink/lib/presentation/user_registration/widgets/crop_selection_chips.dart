import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class CropSelectionChips extends StatelessWidget {
  final List<String> selectedCrops;
  final Function(String) onCropToggle;

  const CropSelectionChips({
    Key? key,
    required this.selectedCrops,
    required this.onCropToggle,
  }) : super(key: key);

  static const List<String> availableCrops = [
    'Maize',
    'Wheat',
    'Rice',
    'Beans',
    'Tomatoes',
    'Potatoes',
    'Onions',
    'Carrots',
    'Cabbage',
    'Spinach',
    'Coffee',
    'Tea',
    'Sugarcane',
    'Cotton',
    'Sunflower',
    'Soybeans',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Crops You Grow',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: availableCrops.map((crop) {
            final isSelected = selectedCrops.contains(crop);
            return GestureDetector(
              onTap: () => onCropToggle(crop),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Padding(
                        padding: EdgeInsets.only(right: 1.w),
                        child: CustomIconWidget(
                          iconName: 'check',
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          size: 3.w,
                        ),
                      ),
                    Text(
                      crop,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.onPrimary
                            : AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
