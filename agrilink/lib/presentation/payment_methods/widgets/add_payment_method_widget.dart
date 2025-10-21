import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AddPaymentMethodWidget extends StatelessWidget {
  final VoidCallback? onAddMpesa;
  final VoidCallback? onAddCard;
  final VoidCallback? onAddPaypal;
  final VoidCallback? onAddBank;

  const AddPaymentMethodWidget({
    Key? key,
    this.onAddMpesa,
    this.onAddCard,
    this.onAddPaypal,
    this.onAddBank,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Payment Method',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 2.5,
            children: [
              _buildPaymentOption(
                'M-Pesa',
                'phone_android',
                const Color(0xFF00A651),
                'Popular in Kenya',
                onAddMpesa,
              ),
              _buildPaymentOption(
                'Credit/Debit Card',
                'credit_card',
                const Color(0xFF1976D2),
                'Visa, Mastercard',
                onAddCard,
              ),
              _buildPaymentOption(
                'PayPal',
                'account_balance_wallet',
                const Color(0xFF0070BA),
                'Global payments',
                onAddPaypal,
              ),
              _buildPaymentOption(
                'Bank Transfer',
                'account_balance',
                const Color(0xFF6B46C1),
                'Direct transfer',
                onAddBank,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    String iconName,
    Color color,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: color,
              size: 5.w,
            ),
            SizedBox(height: 1.h),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
