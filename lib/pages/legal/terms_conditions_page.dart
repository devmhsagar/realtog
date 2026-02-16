import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title("REALTOG – Terms & Conditions"),
              _text("Last Updated: November 2025"),
              _space(),

              _section("1. Eligibility & Intended Use"),
              _text(
                  "REALTOG is intended for use by licensed real estate professionals "
                      "and individuals legally authorized to market real estate. "
                      "You must be at least 18 years old and legally able to enter into agreements."),
              _space(),

              _section("2. User-Generated Content"),
              _bullet("You must own or have permission to use uploaded images."),
              _bullet("You are responsible for all content submitted."),
              _bullet("You must not upload unlawful or infringing material."),
              _space(),

              _section("3. AI Editing Disclaimer"),
              _text(
                  "REALTOG uses automated AI-based editing tools. Results depend on "
                      "the quality of the images you capture. We do not guarantee specific outcomes."),
              _space(),

              _section("4. No Refunds"),
              _text(
                  "All purchases are final and non-refundable, including credits, "
                      "subscriptions, and photo packages."),
              _space(),

              _section("5. License to Use"),
              _text(
                  "REALTOG grants you a limited, non-transferable license to use the app. "
                      "You may not reverse engineer, resell, or misuse the service."),
              _space(),

              _section("6. Intellectual Property"),
              _text(
                  "All branding, technology, and software belong to REALTOG Technologies Inc. "
                      "No ownership is transferred to users."),
              _space(),

              _section("7. Compliance Responsibility"),
              _text(
                  "You are responsible for complying with MLS®, brokerage, and real estate "
                      "regulations applicable in your jurisdiction."),
              _space(),

              _section("8. Limitation of Liability"),
              _text(
                  "REALTOG is not liable for business loss, rejected listings, "
                      "or outcomes related to the use of edited images."),
              _space(),

              _section("9. No Warranty"),
              _text(
                  "The app is provided 'as is' without guarantees of uninterrupted "
                      "operation or specific results."),
              _space(),

              _section("10. Service Availability"),
              _text(
                  "REALTOG may modify or discontinue services at any time without notice."),
              _space(),

              _section("11. Governing Law"),
              _text(
                  "For users in Canada, laws of British Columbia apply. "
                      "For users in the United States, laws of Wyoming apply."),
              _space(),

              _section("12. Updates to Terms"),
              _text(
                  "We may update these Terms periodically. Continued use means "
                      "you accept the revised Terms."),
              _space(),

              _section("13. Contact"),
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
