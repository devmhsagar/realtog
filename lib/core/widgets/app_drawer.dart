import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../pages/legal/data_usage_page.dart';
import '../../pages/legal/privacy_policy_page.dart';
import '../../pages/legal/refund_policy_page.dart';
import '../../pages/legal/terms_conditions_page.dart';
import '../constants/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final String? userName;
  final String? userEmail;

  const AppDrawer({
    super.key,
    this.userName,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _sectionTitle("LEGAL"),

                _drawerItem(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  page: const PrivacyPolicyPage(),
                ),

                _drawerItem(
                  context,
                  icon: Icons.description_outlined,
                  title: "Terms & Conditions",
                  page: const TermsConditionsPage(),
                ),

                _drawerItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: "Refund Policy",
                  page: const RefundPolicyPage(),
                ),

                _drawerItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: "Data Usage & Tracking",
                  page: const DataUsagePage(),
                ),
              ],
            ),
          ),

          _buildFooter(),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 60.h, bottom: 24.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34.r,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 36.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            userName ?? "REALTOG User",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            userEmail ?? "",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SECTION TITLE ----------------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ---------------- DRAWER ITEM ----------------
  Widget _drawerItem(BuildContext context,
      {required IconData icon, required String title, required Widget page}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: TextStyle(fontSize: 15.sp),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  // ---------------- FOOTER ----------------
  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Text(
        "REALTOG © 2025",
        style: TextStyle(
          fontSize: 12.sp,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
