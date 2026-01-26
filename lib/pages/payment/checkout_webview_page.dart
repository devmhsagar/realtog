import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/reusable_appbar.dart';

class CheckoutWebViewPage extends ConsumerStatefulWidget {
  final String sessionUrl;
  final String sessionId;

  const CheckoutWebViewPage({
    super.key,
    required this.sessionUrl,
    required this.sessionId,
  });

  @override
  ConsumerState<CheckoutWebViewPage> createState() =>
      _CheckoutWebViewPageState();
}

class _CheckoutWebViewPageState extends ConsumerState<CheckoutWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Debug: Print the URL being loaded
    debugPrint('Loading checkout URL: ${widget.sessionUrl}');

    try {
      final uri = Uri.parse(widget.sessionUrl);
      if (!uri.hasScheme) {
        throw Exception('Invalid URL: Missing scheme (http/https)');
      }

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              debugPrint('WebView loading progress: $progress%');
            },
            onPageStarted: (String url) {
              debugPrint('Page started loading: $url');
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _error = null;
                  _currentUrl = url;
                });
              }
            },
            onPageFinished: (String url) {
              debugPrint('Page finished loading: $url');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _currentUrl = url;
                });

                // Check if payment was successful or cancelled
                // Stripe typically redirects to success/cancel URLs
                if (url.contains('success') || url.contains('cancel')) {
                  // Handle payment completion
                  _handlePaymentResult(url);
                }
              }
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView error: ${error.description}');
              debugPrint('Error code: ${error.errorCode}');
              debugPrint('Error type: ${error.errorType}');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _error = '${error.description} (Code: ${error.errorCode})';
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              debugPrint('Navigation request: ${request.url}');
              // Allow all navigation
              return NavigationDecision.navigate;
            },
          ),
        );

      // Load URL asynchronously after widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.loadRequest(uri).catchError((error) {
          debugPrint('Error loading URL: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = 'Failed to load URL: ${error.toString()}';
            });
          }
        });
      });
    } catch (e) {
      debugPrint('Error parsing URL: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid URL: ${e.toString()}';
        });
      }
    }
  }

  void _handlePaymentResult(String url) {
    // You can add logic here to handle payment success/failure
    // For example, check the URL for success indicators
    if (url.contains('success')) {
      // Payment successful - you might want to navigate back or show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        });
      }
    } else if (url.contains('cancel')) {
      // Payment cancelled
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ReusableAppBar(title: 'Payment'),
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
          // WebView
          WebViewWidget(controller: _controller),

          // Error overlay
          if (_error != null)
            Container(
              color: AppColors.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.sp,
                      color: AppColors.error,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Error loading payment page',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        _error ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (_currentUrl != null) ...[
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          'URL: $_currentUrl',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _isLoading = true;
                            });
                            _controller.reload();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textLight,
                          ),
                          child: const Text('Retry'),
                        ),
                        SizedBox(width: 16.w),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textSecondary,
                            foregroundColor: AppColors.textLight,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Loading overlay
          if (_isLoading && _error == null)
            Container(
              color: AppColors.surface.withValues(alpha: 0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Loading payment page...',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
