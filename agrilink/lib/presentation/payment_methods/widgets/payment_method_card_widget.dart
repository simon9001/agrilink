import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PaymentMethodCardWidget extends StatelessWidget {
  final Map<String, dynamic> paymentMethod;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDefault;

  const PaymentMethodCardWidget({
    Key? key,
    required this.paymentMethod,
    this.onEdit,
    this.onDelete,
    this.isDefault = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String type = paymentMethod['type'] as String;
    final String displayName = paymentMethod['displayName'] as String;
    final String lastFour = paymentMethod['lastFour'] as String;
    final String? expiryDate = paymentMethod['expiryDate'] as String?;
    final bool isVerified = paymentMethod['isVerified'] as bool;

    return Dismissible(
      key: Key(paymentMethod['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomIconWidget(
          iconName: 'delete',
          color: Colors.white,
          size: 6.w,
        ),
      ),
      onDismissed: (direction) {
        if (onDelete != null) onDelete!();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isDefault
              ? Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 2,
                )
              : Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                ),
          boxShadow: [
            BoxShadow(
              color:
                  AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: _getPaymentTypeColor(type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: _getPaymentTypeIcon(type),
                  color: _getPaymentTypeColor(type),
                  size: 6.w,
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
                        displayName,
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isDefault) ...[
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: Colors.white,
                              fontSize: 8.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Text(
                        type == 'mpesa'
                            ? '+254 ****$lastFour'
                            : '****$lastFour',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (expiryDate != null) ...[
                        SizedBox(width: 2.w),
                        Text(
                          '• $expiryDate',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: isVerified ? 'verified' : 'error',
                        color: isVerified
                            ? AppTheme.getSuccessColor(true)
                            : AppTheme.getWarningColor(true),
                        size: 3.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        isVerified ? 'Verified' : 'Pending Verification',
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: isVerified
                              ? AppTheme.getSuccessColor(true)
                              : AppTheme.getWarningColor(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: CustomIconWidget(
                iconName: 'edit',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 5.w,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'mpesa':
        return 'phone_android';
      case 'card':
        return 'credit_card';
      case 'paypal':
        return 'account_balance_wallet';
      case 'bank':
        return 'account_balance';
      default:
        return 'payment';
    }
  }

  Color _getPaymentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'mpesa':
        return const Color(0xFF00A651);
      case 'card':
        return const Color(0xFF1976D2);
      case 'paypal':
        return const Color(0xFF0070BA);
      case 'bank':
        return const Color(0xFF6B46C1);
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }
}
