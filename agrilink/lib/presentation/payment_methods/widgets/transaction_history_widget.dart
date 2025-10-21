import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TransactionHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final VoidCallback? onViewAll;

  const TransactionHistoryWidget({
    Key? key,
    required this.transactions,
    this.onViewAll,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'history',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Recent Transactions',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View All',
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          transactions.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length > 5 ? 5 : transactions.length,
                  separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _buildTransactionItem(transaction);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'receipt_long',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 12.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'No transactions yet',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Your payment history will appear here',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final String type = transaction['type'] as String;
    final String title = transaction['title'] as String;
    final String subtitle = transaction['subtitle'] as String;
    final String amount = transaction['amount'] as String;
    final String status = transaction['status'] as String;
    final DateTime date = transaction['date'] as DateTime;
    final bool isDebit = transaction['isDebit'] as bool;

    return InkWell(
      onTap: () {
        // Handle transaction details view
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: _getTransactionTypeColor(type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: _getTransactionTypeIcon(type),
                  color: _getTransactionTypeColor(type),
                  size: 5.w,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Text(
                        _formatDate(date),
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: _getStatusColor(status),
                            fontSize: 8.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDebit ? '-' : '+'}$amount',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDebit
                        ? AppTheme.lightTheme.colorScheme.error
                        : AppTheme.getSuccessColor(true),
                  ),
                ),
                SizedBox(height: 0.5.h),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 4.w,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTransactionTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'product':
        return 'shopping_cart';
      case 'consultation':
        return 'medical_services';
      case 'subscription':
        return 'subscriptions';
      case 'refund':
        return 'money_off';
      default:
        return 'payment';
    }
  }

  Color _getTransactionTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'product':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'consultation':
        return const Color(0xFF2196F3);
      case 'subscription':
        return const Color(0xFF9C27B0);
      case 'refund':
        return AppTheme.getSuccessColor(true);
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.getSuccessColor(true);
      case 'pending':
        return AppTheme.getWarningColor(true);
      case 'failed':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
