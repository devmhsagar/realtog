import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Refund Policy"),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title("REALTOG – Refund Policy"),
              _text("Last Updated: November 2025"),
              _space(),

              _section("No Refunds"),
              _text(
                  "REALTOG provides digital editing services that begin "
                      "processing immediately after photos are submitted. "
                      "Because our services involve instant digital customization, "
                      "all purchases are final and non-refundable."),
              _space(),

              _text("We do not offer refunds, credits, or exchanges for:"),
              _bullet("Photo editing credits"),
              _bullet("Subscription fees"),
              _bullet("In-app purchases"),
              _bullet("Accidental purchases"),
              _bullet("Dissatisfaction caused by user-submitted photos"),
              _space(),

              _section("Why We Do Not Offer Refunds"),
              _text(
                  "REALTOG’s results are generated directly from the photos "
                      "a user captures and uploads. The final output reflects "
                      "the quality and condition of the images provided."),
              _space(),

              _text("To ensure the best results, users are responsible for:"),
              _bullet("Following the in-app composition guide"),
              _bullet("Uploading clear, well-lit photos"),
              _bullet("Using a compatible device"),
              _bullet("Preparing rooms and lighting properly"),
              _space(),

              _text(
                  "Because the editing process cannot be reversed once submitted, "
                      "refunds are not possible."),
              _space(),

              _section("Billing & Payments"),
              _text(
                  "All financial transactions are managed securely through "
                      "Apple App Store, Google Play Store, or approved payment providers. "
                      "For billing questions or duplicate charges, please contact us."),
              _space(),

              _section("Quality Concerns"),
              _text(
                  "If you experience a technical issue such as corrupted files, "
                      "missing images, or processing failures, contact us and we will "
                      "review and reprocess the order if necessary."),
              _space(),

              _section("Contact Us"),
              _text("Email: support@realtog.com"),
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
