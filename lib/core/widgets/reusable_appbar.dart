import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

/// Reusable AppBar component with logo, brand name, tagline, and dynamic title
class ReusableAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const ReusableAppBar({super.key, required this.title});

  @override
  Size get preferredSize => Size.fromHeight(120.h);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White icons
        statusBarBrightness: Brightness.dark, // For iOS
      ),
      child: ClipRect(
        child: Container(
          color: AppColors.appBarBackground,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main header with logo, brand name, and tagline - centered
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      // 🔥 Drawer Menu Button (NEW)
                      Builder(
                        builder: (context) => IconButton(
                          icon: Icon(
                            Icons.menu,
                            color: AppColors.textLight,
                            size: 26.sp,
                          ),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),

                      SizedBox(width: 4.w),

                      // 🔥 Center Logo + Brand
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/logo/123.png',
                              height: 32.h,
                              width: 32.w,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 32.h,
                                  width: 32.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 20.sp,
                                    color: AppColors.textLight,
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 6.w),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'R E A L T O G',
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  'YOUR PHONE. YOUR PHOTOS. YOUR EDGE',
                                  style: TextStyle(
                                    fontSize: 7.5.sp,
                                    color: AppColors.textLight.withValues(alpha: 0.9),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 🔥 Right spacer (keeps center aligned)
                      SizedBox(width: 48.w),
                    ],
                  ),

                ),
                // Section title bar - flush with bottom
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  color: AppColors.appBarTitleBackground,
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
        ),
      ),
    );
  }
}
