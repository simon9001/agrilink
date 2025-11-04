import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/user_role.dart';
import '../../routes/app_routes.dart';

class DashboardDemo extends StatelessWidget {
  const DashboardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Demo'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Dashboard Role',
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Choose a role to view the corresponding dashboard layout:',
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 3.h),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 4.w,
                mainAxisSpacing: 3.h,
                childAspectRatio: 1.2,
                children: UserRole.values.map((role) {
                  return _buildRoleCard(context, role);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, UserRole role) {
    Color cardColor;
    IconData icon;
    String description;

    switch (role) {
      case UserRole.FARMER:
        cardColor = Colors.green;
        icon = Icons.agriculture;
        description = 'Manage crops, orders, and farm analytics';
        break;
      case UserRole.BUYER:
        cardColor = Colors.blue;
        icon = Icons.shopping_basket;
        description = 'Browse products and manage purchases';
        break;
      case UserRole.SUPPLIER:
        cardColor = Colors.orange;
        icon = Icons.inventory_2;
        description = 'Manage inventory and supply chain';
        break;
      case UserRole.EXPERT:
        cardColor = Colors.purple;
        icon = Icons.psychology;
        description = 'Provide consultations and advice';
        break;
      case UserRole.ADMIN:
        cardColor = Colors.red;
        icon = Icons.admin_panel_settings;
        description = 'System administration and oversight';
        break;
    }

    return GestureDetector(
      onTap: () => _navigateToDashboard(context, role),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cardColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: cardColor,
                  size: 8.w,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                role.displayName,
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                description,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDashboard(BuildContext context, UserRole role) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to ${role.displayName} Dashboard...'),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 1),
      ),
    );

    // Navigate to the specific dashboard
    Future.delayed(const Duration(milliseconds: 500), () {
      AppRoutes.navigateToRoleDashboard(context, role);
    });
  }
}