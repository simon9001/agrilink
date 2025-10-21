import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SecuritySettingsWidget extends StatefulWidget {
  final bool biometricEnabled;
  final bool transactionPinEnabled;
  final bool notificationsEnabled;
  final Function(bool)? onBiometricChanged;
  final Function(bool)? onTransactionPinChanged;
  final Function(bool)? onNotificationsChanged;
  final VoidCallback? onSetupPin;

  const SecuritySettingsWidget({
    Key? key,
    required this.biometricEnabled,
    required this.transactionPinEnabled,
    required this.notificationsEnabled,
    this.onBiometricChanged,
    this.onTransactionPinChanged,
    this.onNotificationsChanged,
    this.onSetupPin,
  }) : super(key: key);

  @override
  State<SecuritySettingsWidget> createState() => _SecuritySettingsWidgetState();
}

class _SecuritySettingsWidgetState extends State<SecuritySettingsWidget> {
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
            children: [
              CustomIconWidget(
                iconName: 'security',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Security Settings',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSecurityOption(
            'Biometric Authentication',
            'Use fingerprint or face ID for payments',
            'fingerprint',
            widget.biometricEnabled,
            widget.onBiometricChanged,
          ),
          SizedBox(height: 1.5.h),
          _buildSecurityOption(
            'Transaction PIN',
            'Secure your payments with a PIN',
            'pin',
            widget.transactionPinEnabled,
            widget.onTransactionPinChanged,
            showSetup: !widget.transactionPinEnabled,
            onSetup: widget.onSetupPin,
          ),
          SizedBox(height: 1.5.h),
          _buildSecurityOption(
            'Payment Notifications',
            'Get notified about all transactions',
            'notifications',
            widget.notificationsEnabled,
            widget.onNotificationsChanged,
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.getWarningColor(true).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.getWarningColor(true).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.getWarningColor(true),
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Payment limits: \$5,000 daily, \$20,000 monthly',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.getWarningColor(true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption(
    String title,
    String subtitle,
    String iconName,
    bool value,
    Function(bool)? onChanged, {
    bool showSetup = false,
    VoidCallback? onSetup,
  }) {
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: iconName,
              color: AppTheme.lightTheme.colorScheme.primary,
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
              ),
              Text(
                subtitle,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (showSetup)
          TextButton(
            onPressed: onSetup,
            child: Text(
              'Setup',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Switch(
            value: value,
            onChanged: onChanged,
          ),
      ],
    );
  }
}
