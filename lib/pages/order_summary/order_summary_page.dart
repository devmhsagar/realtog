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
  final int declutteringPrice;
  final double totalPrice;
  final List<String>? selectedImagePaths;

  const OrderSummaryPage({
    super.key,
    required this.pricingPlanId,
    required this.basePrice,
    required this.hasDecluttering,
    required this.declutteringPrice,
    required this.totalPrice,
    this.selectedImagePaths,
  });

  @override
  ConsumerState<OrderSummaryPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<OrderSummaryPage> {
  bool _isProcessing = false;
  bool _isLoadingCheckout = false;
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

  Future<void> _handlePaymentMethodTap() async {
    // Validate that images are available
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
      final result = await _paymentService.createCheckoutSession(
        planId: widget.pricingPlanId,
        images: widget.selectedImagePaths!,
      );

      setState(() {
        _isLoadingCheckout = false;
      });

      result.fold(
        (error) {
          // Handle error
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
          // Handle success - navigate to webview with session URL
          final sessionUrl = data['sessionUrl'] as String?;
          final sessionId = data['sessionId'] as String?;

          if (sessionUrl == null || sessionUrl.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid checkout session URL'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 3),
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
                .then((paymentSuccess) {
                  // Handle payment completion
                  if (paymentSuccess == true) {
                    // Payment was successful, you might want to refresh orders or navigate
                    ref.invalidate(ordersProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment completed successfully!'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      // Navigate to home after successful payment
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          context.go('/home');
                        }
                      });
                    }
                  }
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handlePlaceOrder() async {
    // Validate that images are available
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
      // Convert file paths back to XFile objects
      final imageFiles = widget.selectedImagePaths!
          .map((path) => XFile(path))
          .toList();

      final result = await _orderService.createOrder(
        planId: widget.pricingPlanId,
        images: imageFiles,
      );

      setState(() {
        _isProcessing = false;
      });

      result.fold(
        (error) {
          // Handle error
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
          // Handle success
          if (mounted) {
            // Invalidate orders provider to refresh the orders list
            ref.invalidate(ordersProvider);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order placed successfully!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );

            // Navigate to home after successful order
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
            duration: const Duration(seconds: 3),
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
              // Order Summary Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                    if (widget.hasDecluttering) ...[
                      SizedBox(height: 8.h),
                      _buildSummaryRow(
                        'Image Decluttering',
                        '+ CA\$${widget.declutteringPrice}',
                        isAddon: true,
                      ),
                    ],
                    Divider(height: 24.h, thickness: 1),
                    _buildSummaryRow(
                      'Total',
                      'CA\$${widget.totalPrice.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              // Payment Method Section
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              InkWell(
                onTap: _isLoadingCheckout ? null : _handlePaymentMethodTap,
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: _isLoadingCheckout
                            ? SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.payment,
                                size: 24.sp,
                                color: AppColors.primary,
                              ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stripe Payment',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _isLoadingCheckout
                                  ? 'Creating checkout session...'
                                  : 'Secure payment processing',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16.sp,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              // Place Order Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePlaceOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  child: _isProcessing
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
                          'Confirm Order',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 8.h),
              // Security Note
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Your payment information is secure and encrypted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
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
