import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class LoginHeaderWidget extends StatelessWidget {
  const LoginHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
          height: 12.h,
          width: 24.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/img_app_logo.svg',
              height: 8.h,
              width: 16.w,
              colorFilter: ColorFilter.mode(
                AppTheme.lightTheme.primaryColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),

        SizedBox(height: 3.h),

        // Welcome text
        Text(
          'Welcome Back',
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.primaryColor,
          ),
        ),

        SizedBox(height: 1.h),

        // Subtitle
        Text(
          'Sign in to continue to AgriLink',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
