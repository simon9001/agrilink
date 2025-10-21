import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TimeSlotSelector extends StatelessWidget {
  final List<String> timeSlots;
  final String? selectedTimeSlot;
  final Function(String) onTimeSlotSelected;

  const TimeSlotSelector({
    Key? key,
    required this.timeSlots,
    required this.selectedTimeSlot,
    required this.onTimeSlotSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Time Slots',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          timeSlots.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      CustomIconWidget(
                        iconName: 'schedule',
                        color: Colors.grey,
                        size: 32,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'No available slots for this date',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: timeSlots.map((timeSlot) {
                    final isSelected = selectedTimeSlot == timeSlot;
                    return GestureDetector(
                      onTap: () => onTimeSlotSelected(timeSlot),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          timeSlot,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.lightTheme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
