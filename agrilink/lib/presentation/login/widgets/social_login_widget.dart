import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class SocialLoginWidget extends StatelessWidget {
  final bool isLoading;

  const SocialLoginWidget({
    Key? key,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with "or" text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey[300],
                thickness: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'or',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 12.sp,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey[300],
                thickness: 1,
              ),
            ),
          ],
        ),

        SizedBox(height: 3.h),

        // Google sign in button
        _buildSocialButton(
          context: context,
          label: 'Continue with Google',
          icon: Icons.g_mobiledata,
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          borderColor: Colors.grey[300]!,
          onPressed: () => _handleGoogleSignIn(context),
        ),

        SizedBox(height: 2.h),

        // Demo credentials info
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Demo Credentials',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Email: farmer@agrilink.com\nPassword: farmer123',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.blue[700],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Icon(
          icon,
          size: 20.sp,
          color: textColor,
        ),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      // Note: This is a placeholder for Google OAuth implementation
      // In a real app, you would implement actual Google OAuth
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In not implemented in demo'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
