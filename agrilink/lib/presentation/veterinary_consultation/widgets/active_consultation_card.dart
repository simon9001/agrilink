import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActiveConsultationCard extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final VoidCallback onJoinCall;

  const ActiveConsultationCard({
    Key? key,
    required this.consultation,
    required this.onJoinCall,
  }) : super(key: key);

  @override
  State<ActiveConsultationCard> createState() => _ActiveConsultationCardState();
}

class _ActiveConsultationCardState extends State<ActiveConsultationCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getTimeRemaining() {
    final DateTime appointmentTime =
        DateTime.parse(widget.consultation['appointmentTime'] as String);
    final Duration difference = appointmentTime.difference(DateTime.now());

    if (difference.isNegative) {
      return 'Starting now';
    }

    final int hours = difference.inHours;
    final int minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else {
      return '${minutes}m remaining';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isStartingSoon =
        DateTime.parse(widget.consultation['appointmentTime'] as String)
                .difference(DateTime.now())
                .inMinutes <=
            5;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStartingSoon
              ? AppTheme.getSuccessColor(true)
              : AppTheme.lightTheme.colorScheme.primary,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isStartingSoon ? _pulseAnimation.value : 1.0,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: isStartingSoon
                            ? AppTheme.getSuccessColor(true)
                            : AppTheme.lightTheme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'video_call',
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Consultation',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      _getTimeRemaining(),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: isStartingSoon
                            ? AppTheme.getSuccessColor(true)
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageWidget(
                    imageUrl: widget.consultation['vetPhoto'] as String,
                    width: 12.w,
                    height: 12.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.consultation['vetName'] as String,
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.consultation['serviceType'] as String,
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.consultation['scheduledTime'] as String,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: isStartingSoon ? widget.onJoinCall : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isStartingSoon
                    ? AppTheme.getSuccessColor(true)
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'video_call',
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    isStartingSoon ? 'Join Call' : 'Call Not Ready',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
