import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class DataUsagePage extends StatelessWidget {
  const DataUsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Usage & Tracking"),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title("REALTOG – Data Usage & Tracking"),
              _space(),

              _text(
                  "REALTOG uses device-based storage and tracking technologies to "
                      "support core functionality, improve performance, and enhance your "
                      "experience while using the App."),
              _space(),

              _section("1. What We Use Instead of Cookies"),
              _bullet("Secure local storage within the app"),
              _bullet("Device identifiers (iOS / Android system IDs)"),
              _bullet("Authentication tokens for login sessions"),
              _bullet("Analytics and crash reporting tools"),
              _space(),

              _section("2. Why These Technologies Are Used"),
              _bullet("Provide secure access to REALTOG services"),
              _bullet("Ensure photo uploads and editing workflows function properly"),
              _bullet("Monitor performance and fix crashes"),
              _bullet("Improve usability and reliability"),
              _bullet("Comply with Apple and Google platform requirements"),
              _space(),

              _section("3. Analytics & Performance Monitoring"),
              _text(
                  "We may use trusted tools such as Firebase Analytics, Apple App Analytics, "
                      "and crash reporting systems to understand performance and improve stability. "
                      "No personal data is sold or used for advertising."),
              _space(),

              _section("4. Third-Party Service Providers"),
              _text(
                  "REALTOG relies on secure third-party services such as cloud storage, "
                      "payment providers, and analytics platforms. These providers operate "
                      "under strict privacy and data protection agreements."),
              _space(),

              _section("5. Your Controls"),
              _bullet("Disable advertising tracking from device settings"),
              _bullet("Reset device identifiers"),
              _bullet("Clear app data or uninstall the app"),
              _bullet("Manage permissions from system settings"),
              _space(),

              _section("6. Data Retention"),
              _text(
                  "We retain technical and usage data only as long as necessary to "
                      "deliver services, maintain security, and comply with legal obligations."),
              _space(),

              _section("7. Updates"),
              _text(
                  "We may update this policy to reflect platform requirements or feature "
                      "changes. Users will be notified when material updates occur."),
              _space(),

              _section("8. Contact"),
              _text("Email: support@realtog.com\nWebsite: www.realtog.com"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Text(
    text,
    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
  );

  Widget _section(String text) => Padding(
    padding: EdgeInsets.only(top: 18.h, bottom: 6.h),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _text(String text) => Text(
    text,
    style: TextStyle(height: 1.6, fontSize: 14.sp),
  );

  Widget _bullet(String text) => Padding(
    padding: EdgeInsets.only(left: 6.w, top: 4.h),
    child: Text("• $text", style: TextStyle(fontSize: 14.sp)),
  );

  Widget _space() => SizedBox(height: 12.h);
}
