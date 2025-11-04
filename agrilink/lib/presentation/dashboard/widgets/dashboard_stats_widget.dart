import 'dart:math';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

enum Metric {
  REVENUE,
  GROWTH,
  COMPLETED,
  CANCELLED,
  PENDING,
  REFUNDED,
  ERROR,
}

class DashboardStats extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isFarmer;
  final bool isExpert;
  final bool isSupplier;

  const DashboardStats({
    super.key,
    required this.stats,
    this.isFarmer = false,
    this.isExpert = false,
    this.isSupplier = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatsGrid(),
        SizedBox(height: 4.h),
        _buildActivitySummary(),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 4.w,
      mainAxisSpacing: 4.h,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Orders',
          stats['total_orders']?.toString() ?? '0',
          Icons.shopping_cart,
          _getMetricColor(Metric.COMPLETED),
        ),
        _buildMetricCard(
          'Pending Orders',
          stats['pending_orders']?.toString() ?? '0',
          Icons.pending,
          _getMetricColor(Metric.PENDING),
        ),
        _buildMetricCard(
          'Completed',
          stats['completed_orders']?.toString() ?? '0',
          Icons.check_circle,
          _getMetricColor(Metric.COMPLETED),
        ),
        _buildMetricCard(
          'Revenue',
          '\$${stats['total_revenue'] ?? '0'}',
          Icons.trending_up,
          _getMetricColor(Metric.REVENUE),
        ),
        if (isFarmer || isSupplier)
          _buildMetricCard(
            'Rating',
            '${stats['rating'] ?? '0.0'}',
            Icons.star,
            _getMetricColor(Metric.COMPLETED),
          ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: 12.h,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              title,
              style: AppTheme.textTheme.titleMedium?.copyWith(
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: AppTheme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummary() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Today\'s Activities',
            '${stats['today_activities'] ?? '0'} tasks completed',
            _getMetricColor(Metric.REVENUE),
          ),
          SizedBox(height: 1.h),
          _buildSummaryRow(
            'Pending Tasks',
            '${stats['pending_tasks'] ?? '0'} tasks',
            _getMetricColor(Metric.PENDING),
          ),
          SizedBox(height: 1.h),
          _buildSummaryRow(
            'Completion Rate',
            '${_getCompletionPercentage()}%',
            _getCompletionColor(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: AppTheme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: AppTheme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getCompletionPercentage() {
    final completedOrders = (stats['completed_orders'] as int?) ?? 0;
    final totalOrders = (stats['total_orders'] as int?) ?? 1;

    if (totalOrders == 0) return '0.0';

    return ((completedOrders / totalOrders) * 100).toStringAsFixed(1);
  }

  Color _getCompletionColor() {
    final completionRate = double.tryParse(_getCompletionPercentage()) ?? 0.0;

    if (completionRate >= 95) return Colors.green;
    if (completionRate >= 80) return Colors.orange;
    if (completionRate >= 70) return Colors.yellow;
    return Colors.red;
  }

  Color _getMetricColor(Metric metric) {
    switch (metric) {
      case Metric.REVENUE:
        return Colors.green;
      case Metric.GROWTH:
        return Colors.blue;
      case Metric.COMPLETED:
        return Colors.green;
      case Metric.CANCELLED:
        return Colors.red;
      case Metric.PENDING:
        return Colors.orange;
      case Metric.REFUNDED:
        return Colors.purple;
      case Metric.ERROR:
        return Colors.red;
    }
  }
}