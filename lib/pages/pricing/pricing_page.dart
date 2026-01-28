import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/reusable_appbar.dart';
import '../../models/pricing_model.dart';
import '../../providers/pricing_provider.dart';

class PricingPage extends ConsumerStatefulWidget {
  final String id;

  const PricingPage({super.key, required this.id});

  @override
  ConsumerState<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends ConsumerState<PricingPage> {
  bool _isDeclutteringSelected = false;

  List<String> _getPackageFeatures(PricingModel plan) {
    // Use whatsIncluded from API if available, otherwise fallback to default features
    if (plan.whatsIncluded != null && plan.whatsIncluded!.isNotEmpty) {
      return plan.whatsIncluded!;
    }
    return [
      'Professional high-resolution photos',
      'Enhanced image quality and editing',
      'Quick turnaround time',
      'Expert photography techniques',
      'Optimized for online listings',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pricingAsync = ref.watch(pricingPlanProvider(widget.id));

    return Scaffold(
      appBar: const ReusableAppBar(title: 'Pricing Details'),
      body: pricingAsync.when(
        data: (plan) {
          final bool hasOptionalFeatures =
              plan.optionalFeatures != null &&
              plan.optionalFeatures!.isNotEmpty;
          final double declutteringPrice = hasOptionalFeatures
              ? plan.optionalFeatures!.first.extraCharge
              : 0.0;
          double totalPrice = plan.price;

          if (hasOptionalFeatures && _isDeclutteringSelected) {
            totalPrice = plan.price + declutteringPrice;
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card matching home tab design
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price section (white background)
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  plan.name,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (_isDeclutteringSelected)
                                    Text(
                                      '\$${plan.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  Text(
                                    '\$${totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Green bar with description and View Details button
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(11.r),
                              bottomRight: Radius.circular(11.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  'Includes ${plan.maxImages} AI professionally edited photos.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Features Section
                  Text(
                    'What\'s Included',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ..._getPackageFeatures(plan).map(
                    (feature) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h, left: 16.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 14.sp,
                              color: AppColors.textLight,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasOptionalFeatures) ...[
                    SizedBox(height: 16.h),
                    // Image Decluttering Option (from optionalFeatures)
                    Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDeclutteringSelected = !_isDeclutteringSelected;
                          });
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                color: _isDeclutteringSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              child: _isDeclutteringSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 14.sp,
                                      color: AppColors.textLight,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Image Decluttering',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    '+\$${declutteringPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 20.h),
                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(
                          '/select-images',
                          extra: {
                            'pricingPlanId': plan.id,
                            'basePrice': plan.price,
                            'hasDecluttering': _isDeclutteringSelected,
                            'declutteringPrice': declutteringPrice,
                            'totalPrice': totalPrice,
                            'maxImages': plan.maxImages,
                            'selectedOptionalFeatures':
                                hasOptionalFeatures && _isDeclutteringSelected
                                ? plan.optionalFeatures!
                                      .map(
                                        (f) => {
                                          'name': f.name,
                                          'extraCharge': f.extraCharge,
                                        },
                                      )
                                      .toList()
                                : null,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
                SizedBox(height: 16.h),
                Text(
                  'Failed to load pricing details',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  error.toString(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(pricingPlanProvider(widget.id));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Go Back',
                    style: TextStyle(color: AppColors.primary, fontSize: 16.sp),
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
