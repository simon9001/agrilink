import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class LoginFormWidget extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool isLoading;
  final VoidCallback onLogin;

  const LoginFormWidget({
    Key? key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.isLoading,
    required this.onLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email field
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !isLoading,
          style: GoogleFonts.inter(fontSize: 14.sp),
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: 13.sp,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: Colors.grey[600],
              size: 20.sp,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.lightTheme.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),

        SizedBox(height: 2.h),

        // Password field
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          enabled: !isLoading,
          style: GoogleFonts.inter(fontSize: 14.sp),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: 13.sp,
            ),
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: Colors.grey[600],
              size: 20.sp,
            ),
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
                size: 20.sp,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.lightTheme.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),

        SizedBox(height: 3.h),

        // Login button
        ElevatedButton(
          onPressed: isLoading ? null : onLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            shadowColor: AppTheme.lightTheme.primaryColor.withAlpha(77),
          ),
          child: isLoading
              ? SizedBox(
                  height: 2.h,
                  width: 2.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Sign In',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}
