import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class MarketOverviewWidget extends StatelessWidget {
  final Map<String, dynamic> marketData;

  const MarketOverviewWidget({
    super.key,
    required this.marketData,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 2.h),
          _buildMarketStats(),
          SizedBox(height: 2.h),
          _buildTrendingCrops(),
          SizedBox(height: 2.h),
          _buildPriceAlerts(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Market Overview',
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 3.w,
              ),
              SizedBox(width: 1.w),
              Text(
                'Live',
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarketStats() {
    final stats = [
      {
        'label': 'Active Listings',
        'value': marketData['active_listings']?.toString() ?? '0',
        'change': '+12%',
        'change_type': 'positive',
        'icon': Icons.list_alt,
        'color': Colors.blue,
      },
      {
        'label': 'Avg. Price/kg',
        'value': '\$${marketData['average_price']?.toString() ?? '0.00'}',
        'change': '+5.2%',
        'change_type': 'positive',
        'icon': Icons.attach_money,
        'color': Colors.green,
      },
      {
        'label': 'Market Demand',
        'value': '${marketData['demand_score']?.toString() ?? '85'}%',
        'change': '+8.1%',
        'change_type': 'positive',
        'icon': Icons.trending_up,
        'color': Colors.orange,
      },
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 1.w),
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: (stat['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 5.w,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  stat['label'] as String,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  stat['value'] as String,
                  style: AppTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: stat['color'] as Color,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      stat['change_type'] == 'positive'
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: stat['change_type'] == 'positive'
                          ? Colors.green
                          : Colors.red,
                      size: 3.w,
                    ),
                    Text(
                      stat['change'] as String,
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: stat['change_type'] == 'positive'
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendingCrops() {
    final trendingCrops = marketData['trending_crops'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Crops',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        if (trendingCrops.isEmpty)
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No trending data available',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          )
        else
          Column(
            children: trendingCrops.take(3).map((crop) {
              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.eco,
                        color: Colors.green,
                        size: 4.w,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            crop['name'] as String? ?? 'Unknown Crop',
                            style: AppTheme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '\$${crop['price']?.toString() ?? '0.00'}/kg',
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Colors.green,
                          size: 3.w,
                        ),
                        Text(
                          '+${crop['change']?.toString() ?? '0'}%',
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPriceAlerts() {
    final alerts = marketData['price_alerts'] as List<dynamic>? ?? [];

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Alerts',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Colors.orange,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${alerts.length} price alerts active',
                      style: AppTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                    Text(
                      'Track your favorite crops and get notified of price changes',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.orange,
                size: 3.w,
              ),
            ],
          ),
        ),
      ],
    );
  }
}