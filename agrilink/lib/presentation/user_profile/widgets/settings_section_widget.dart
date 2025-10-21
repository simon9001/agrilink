import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsSectionWidget extends StatelessWidget {
  final VoidCallback onNavigateToPaymentMethods;

  const SettingsSectionWidget({
    Key? key,
    required this.onNavigateToPaymentMethods,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              "Settings & Preferences",
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildSettingsGroup("Account", [
            {
              "title": "Account Management",
              "subtitle": "Update your account details",
              "icon": "account_circle",
              "onTap": () {},
            },
            {
              "title": "Payment Methods",
              "subtitle": "Manage your payment options",
              "icon": "payment",
              "onTap": onNavigateToPaymentMethods,
            },
            {
              "title": "Privacy Settings",
              "subtitle": "Control your privacy preferences",
              "icon": "privacy_tip",
              "onTap": () {},
            },
          ]),
          _buildDivider(),
          _buildSettingsGroup("Notifications", [
            {
              "title": "Push Notifications",
              "subtitle": "Order updates and messages",
              "icon": "notifications",
              "hasSwitch": true,
              "switchValue": true,
            },
            {
              "title": "Email Notifications",
              "subtitle": "Marketing and promotional emails",
              "icon": "email",
              "hasSwitch": true,
              "switchValue": false,
            },
          ]),
          _buildDivider(),
          _buildSettingsGroup("Agricultural Preferences", [
            {
              "title": "Crop Interests",
              "subtitle": "Customize your feed content",
              "icon": "eco",
              "onTap": () {},
            },
            {
              "title": "Farming Methods",
              "subtitle": "Organic, conventional, sustainable",
              "icon": "nature",
              "onTap": () {},
            },
            {
              "title": "Location Services",
              "subtitle": "Find nearby farmers and products",
              "icon": "location_on",
              "hasSwitch": true,
              "switchValue": true,
            },
          ]),
          _buildDivider(),
          _buildSettingsGroup("Support", [
            {
              "title": "Help Center",
              "subtitle": "FAQs and support articles",
              "icon": "help",
              "onTap": () {},
            },
            {
              "title": "Contact Support",
              "subtitle": "Get help from our team",
              "icon": "support_agent",
              "onTap": () {},
            },
            {
              "title": "Report Issue",
              "subtitle": "Report bugs or problems",
              "icon": "bug_report",
              "onTap": () {},
            },
          ]),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Text(
            title,
            style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
              color: AppTheme.lightTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items.map((item) => _buildSettingsItem(item)).toList(),
      ],
    );
  }

  Widget _buildSettingsItem(Map<String, dynamic> item) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      leading: Container(
        width: 10.w,
        height: 10.w,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomIconWidget(
          iconName: item["icon"] as String,
          color: AppTheme.lightTheme.primaryColor,
          size: 5.w,
        ),
      ),
      title: Text(
        item["title"] as String,
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: item["subtitle"] != null
          ? Text(
              item["subtitle"] as String,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: item["hasSwitch"] == true
          ? Switch(
              value: item["switchValue"] as bool? ?? false,
              onChanged: (value) {
                // Handle switch toggle
              },
            )
          : CustomIconWidget(
              iconName: 'chevron_right',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
      onTap: item["hasSwitch"] != true ? item["onTap"] as VoidCallback? : null,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
      indent: 4.w,
      endIndent: 4.w,
    );
  }
}
