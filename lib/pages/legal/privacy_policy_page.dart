import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title("REALTOG – Privacy Policy"),
              _text("Last Updated: November 19, 2025"),
              _space(),

              _text(
                  "REALTOG (“we”, “our”, “us”) provides REALTORS® and property professionals "
                      "with a mobile solution to capture listing photos and receive professionally "
                      "edited images using AI-powered processing."),
              _space(),

              _section("1. Information We Collect"),
              _bullet("Name, email address, and optional phone number."),
              _bullet("Photos you upload for editing."),
              _bullet("Device and app performance data (non-identifiable)."),
              _bullet("Crash logs and analytics to improve performance."),
              _bullet("Payment handled securely by Apple / Google / Stripe."),
              _space(),

              _section("2. Camera & Media Access"),
              _text(
                  "Camera access is used only when you choose to capture images. "
                      "We never access your photo library without your permission."),
              _space(),

              _section("3. How We Use Your Information"),
              _bullet("Deliver AI-powered photo editing services."),
              _bullet("Maintain and support your account."),
              _bullet("Improve app features and reliability."),
              _bullet("Process secure transactions."),
              _bullet("Prevent fraud and ensure platform safety."),
              _space(),

              _section("4. Photo Processing & Storage"),
              _bullet("Images are uploaded securely."),
              _bullet("Used only to generate edited photos."),
              _bullet("Stored temporarily and deleted automatically."),
              _bullet("Never used to train AI without consent."),
              _space(),

              _section("5. Data Sharing"),
              _text(
                  "We share data only with trusted service providers such as cloud storage, "
                      "AI processing tools, analytics providers, and payment processors. "
                      "We never sell your data."),
              _space(),

              _section("6. Data Security"),
              _bullet("Encrypted transmission (HTTPS/TLS)."),
              _bullet("Secure cloud storage."),
              _bullet("Password hashing and restricted access."),
              _space(),

              _section("7. Your Rights"),
              _bullet("Update your account information anytime."),
              _bullet("Delete uploaded photos."),
              _bullet("Request account deletion."),
              _space(),

              _section("8. Children's Privacy"),
              _text(
                  "REALTOG is not intended for individuals under 18. "
                      "We do not knowingly collect data from children."),
              _space(),

              _section("9. International Users"),
              _text(
                  "Data may be processed in Canada, the United States, or other regions "
                      "where our service providers operate."),
              _space(),

              _section("10. Changes to This Policy"),
              _text(
                  "We may update this Privacy Policy periodically. "
                      "Continued use of the App means you accept updates."),
              _space(),

              _section("11. Contact Us"),
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
