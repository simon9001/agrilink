import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    Key? key,
    required this.password,
  }) : super(key: key);

  PasswordStrength _getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return AppTheme.lightTheme.colorScheme.error;
      case PasswordStrength.medium:
        return AppTheme.getWarningColor(true);
      case PasswordStrength.strong:
        return AppTheme.getSuccessColor(true);
      case PasswordStrength.none:
        return AppTheme.lightTheme.colorScheme.outline;
    }
  }

  String _getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak - Add more characters and variety';
      case PasswordStrength.medium:
        return 'Medium - Good but could be stronger';
      case PasswordStrength.strong:
        return 'Strong - Great password!';
      case PasswordStrength.none:
        return 'Enter a password';
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _getPasswordStrength(password);
    final color = _getStrengthColor(strength);
    final strengthText = _getStrengthText(strength);

    return password.isEmpty
        ? SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.h),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 0.5.h,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: strength == PasswordStrength.none
                            ? 0.0
                            : strength == PasswordStrength.weak
                                ? 0.33
                                : strength == PasswordStrength.medium
                                    ? 0.66
                                    : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Text(
                strengthText,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 10.sp,
                ),
              ),
            ],
          );
  }
}

enum PasswordStrength { none, weak, medium, strong }
