import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

/// Reusable AppBar component with logo, brand name, tagline, and dynamic title
class ReusableAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const ReusableAppBar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => Size.fromHeight(120.h);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.appBarBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Main header with logo, brand name, and tagline
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  // Logo
                  Image.asset(
                    'assets/logo/appbar_logo.png',
                    height: 32.h,
                    width: 32.w,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 12.w),
                  // Brand name and tagline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REALTOG',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'YOUR PHONE, YOUR PHOTOS, YOUR EDGE.',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textLight.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Section title bar
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              color: AppColors.appBarBackground.withValues(alpha: 0.95),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

