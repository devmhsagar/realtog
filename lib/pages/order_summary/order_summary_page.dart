import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/reusable_appbar.dart';
import '../../core/services/order_service.dart';
import '../../core/services/payment_service.dart';
import '../../providers/order_provider.dart';
import '../payment/checkout_webview_page.dart';

class OrderSummaryPage extends ConsumerStatefulWidget {
  final String pricingPlanId;
  final double basePrice;
  final bool hasDecluttering;
  final double declutteringPrice;
  final double totalPrice;
  final List<String>? selectedImagePaths;
  final List<Map<String, dynamic>>? selectedOptionalFeatures;

  const OrderSummaryPage({
    super.key,
    required this.pricingPlanId,
    required this.basePrice,
    required this.hasDecluttering,
    required this.declutteringPrice,
    required this.totalPrice,
    this.selectedImagePaths,
    this.selectedOptionalFeatures,
  });

  @override
  ConsumerState<OrderSummaryPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<OrderSummaryPage> {
  bool _isProcessing = false;
  bool _isLoadingCheckout = false;
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

  // ✅ VAT Calculation Added (Safe)
  double get _vatAmount => widget.basePrice * 0.05;
  double get _finalTotal => widget.totalPrice + _vatAmount;

  Future<void> _handlePaymentMethodTap() async {
    if (widget.selectedImagePaths == null ||
        widget.selectedImagePaths!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No images selected. Please go back and select images.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingCheckout = true;
    });

    try {
      final imageFiles =
      widget.selectedImagePaths!.map((path) => XFile(path)).toList();

      final optionalFeatures =
      widget.hasDecluttering &&
          widget.selectedOptionalFeatures != null &&
          widget.selectedOptionalFeatures!.isNotEmpty
          ? widget.selectedOptionalFeatures
          : null;

      final result = await _paymentService.createCheckoutSession(
        planId: widget.pricingPlanId,
        images: imageFiles,
        optionalFeatures: optionalFeatures,
      );

      setState(() {
        _isLoadingCheckout = false;
      });

      result.fold(
            (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $error'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
            (data) {
          final sessionUrl = data['sessionUrl'] as String?;
          final sessionId = data['sessionId'] as String?;

          if (sessionUrl == null || sessionUrl.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid checkout session URL'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }

          if (mounted) {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => CheckoutWebViewPage(
                  sessionUrl: sessionUrl,
                  sessionId: sessionId ?? '',
                ),
              ),
            )
                .then((_) {
              ref.invalidate(ordersProvider);
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _isLoadingCheckout = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handlePlaceOrder() async {
    if (widget.selectedImagePaths == null ||
        widget.selectedImagePaths!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No images selected. Please go back and select images.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final imageFiles =
      widget.selectedImagePaths!.map((path) => XFile(path)).toList();

      final result = await _orderService.createOrder(
        planId: widget.pricingPlanId,
        images: imageFiles,
      );

      setState(() {
        _isProcessing = false;
      });

      result.fold(
            (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $error'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
            (data) {
          if (mounted) {
            ref.invalidate(ordersProvider);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order placed successfully!'),
                backgroundColor: AppColors.success,
              ),
            );

            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                context.go('/home');
              }
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ReusableAppBar(title: 'Order Summary'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    _buildSummaryRow(
                      'Base Price',
                      'CA\$${widget.basePrice.toStringAsFixed(2)}',
                    ),

                    SizedBox(height: 8.h),

                    // ✅ VAT Row Added
                    _buildSummaryRow(
                      'GST (5%)',
                      '+ CA\$${_vatAmount.toStringAsFixed(2)}',
                      isAddon: true,
                    ),

                    if (widget.hasDecluttering) ...[
                      SizedBox(height: 8.h),
                      _buildSummaryRow(
                        'Image Decluttering',
                        '+ CA\$${widget.declutteringPrice.toStringAsFixed(2)}',
                        isAddon: true,
                      ),
                    ],

                    Divider(height: 24.h, thickness: 1),

                    _buildSummaryRow(
                      'Total',
                      'CA\$${_finalTotal.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                  _isLoadingCheckout ? null : _handlePaymentMethodTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  child: _isLoadingCheckout
                      ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textLight,
                      ),
                    ),
                  )
                      : Text(
                    'Pay Now',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                'Your payment information is secure and encrypted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value, {
        bool isAddon = false,
        bool isTotal = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 16.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isAddon ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20.sp : 16.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isAddon ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}