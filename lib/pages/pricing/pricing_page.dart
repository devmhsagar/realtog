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

  /// Get decluttering price based on max_images
  int _getDeclutteringPrice(int maxImages) {
    switch (maxImages) {
      case 10:
        return 15;
      case 20:
        return 25;
      case 40:
        return 40;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricingAsync = ref.watch(pricingPlanProvider(widget.id));

    return Scaffold(
      appBar: const ReusableAppBar(
        title: 'Pricing Details',
      ),
      body: pricingAsync.when(
        data: (plan) {
          // Calculate decluttering price and total price
          final int declutteringPrice = _getDeclutteringPrice(plan.maxImages);
          double totalPrice = plan.price;
          
          if (_isDeclutteringSelected) {
            totalPrice = plan.price + declutteringPrice;
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card with Gradient
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          plan.shortDescription ??
                              'Professional photography service',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textLight.withValues(alpha: 0.9),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.textLight.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isDeclutteringSelected)
                                      Text(
                                        'CA\$${plan.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: AppColors.textLight.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      'CA\$${totalPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textLight.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 24.sp,
                                    color: AppColors.textLight,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    '${plan.maxImages}',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  Text(
                                    'Photos',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: AppColors.textLight.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.w),
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
                  SizedBox(height: 16.h),
                  // Image Decluttering Option
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _isDeclutteringSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: _isDeclutteringSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isDeclutteringSelected,
                          onChanged: (value) {
                            setState(() {
                              _isDeclutteringSelected = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image Decluttering',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '+ CA\$$declutteringPrice',
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
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Place Order',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
