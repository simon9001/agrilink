import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class QuickActionsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final String title;
  final bool isGridView;

  const QuickActionsWidget({
    super.key,
    required this.actions,
    this.title = 'Quick Actions',
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

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
          Text(
            title,
            style: AppTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          isGridView ? _buildGridActions() : _buildListActions(),
        ],
      ),
    );
  }

  Widget _buildGridActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 2.w,
      mainAxisSpacing: 2.h,
      childAspectRatio: 0.8,
      children: actions.map((action) => _buildActionCard(action)).toList(),
    );
  }

  Widget _buildListActions() {
    return Column(
      children: actions.map((action) {
        return Padding(
          padding: EdgeInsets.only(bottom: 1.h),
          child: _buildActionCard(action),
        );
      }).toList(),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: () => _handleActionTap(action),
      child: Container(
        padding: isGridView ? EdgeInsets.all(2.w) : EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: (action['color'] as Color?)?.withOpacity(0.1) ?? Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (action['color'] as Color?)?.withOpacity(0.3) ?? Colors.grey[300]!,
          ),
        ),
        child: isGridView ? _buildGridActionContent(action) : _buildListActionContent(action),
      ),
    );
  }

  Widget _buildGridActionContent(Map<String, dynamic> action) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          action['icon'] as IconData? ?? Icons.dashboard,
          color: action['color'] as Color? ?? AppTheme.primaryColor,
          size: 6.w,
        ),
        SizedBox(height: 1.h),
        Text(
          action['title'] as String? ?? 'Action',
          style: AppTheme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildListActionContent(Map<String, dynamic> action) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: (action['color'] as Color?)?.withOpacity(0.1) ?? Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            action['icon'] as IconData? ?? Icons.dashboard,
            color: action['color'] as Color? ?? AppTheme.primaryColor,
            size: 5.w,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action['title'] as String? ?? 'Action',
                style: AppTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (action['description'] != null)
                Text(
                  action['description'] as String? ?? '',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 3.w,
          color: Colors.grey[400],
        ),
      ],
    );
  }

  void _handleActionTap(Map<String, dynamic> action) {
    final route = action['route'] as String?;
    final onTap = action['onTap'] as VoidCallback?;

    if (onTap != null) {
      onTap();
    } else if (route != null) {
      Navigator.pushNamed(Get.context!, route);
    } else {
      // Show a snackbar or dialog for unimplemented actions
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('Action "${action['title']}" not implemented yet'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  bool get isGridView => !(actions.length > 4);
}