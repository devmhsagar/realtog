import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/register_page.dart';
import '../../pages/auth/forgot_password_page.dart';
import '../../pages/auth/otp_verification_page.dart';
import '../../pages/auth/reset_password_page.dart';
import '../../pages/home/home_page.dart';
import '../../pages/pricing/pricing_page.dart';
import '../../pages/select_images/select_images_page.dart';
import '../../pages/order_summary/order_summary_page.dart';
import '../../pages/payment/checkout_webview_page.dart';
import '../../providers/auth_provider.dart';

/// Router configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  // Don't watch auth state here - refreshListenable handles router updates
  // This prevents unnecessary router rebuilds during registration

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isOnLoginPage = state.matchedLocation == '/login';
      final isOnRegisterPage = state.matchedLocation == '/register';
      final isOnHomePage = state.matchedLocation == '/home';
      final isOnPricingPage = state.matchedLocation.startsWith('/pricing/');
      final isOnSelectImagesPage = state.matchedLocation.startsWith(
        '/select-images',
      );
      final isOnPaymentPage = state.matchedLocation.startsWith('/payment');
      final isOnCheckoutPage = state.matchedLocation.startsWith('/checkout');

      // If still loading auth state, don't redirect yet
      if (authState.isLoading) {
        return null;
      }

      // Never redirect away from register page (except if authenticated, then go to home)
      // This allows the register page to handle its own state and navigation
      if (isOnRegisterPage) {
        // Only redirect if authenticated (should go to home)
        if (isAuthenticated) {
          return '/home';
        }
        // Otherwise, stay on register page - let it handle its own navigation
        return null;
      }

      // If authenticated and trying to access auth pages, redirect to home
      if (isAuthenticated && isOnLoginPage) {
        return '/home';
      }

      // If not authenticated and trying to access protected pages, redirect to login
      if (!isAuthenticated &&
          (isOnHomePage ||
              isOnPricingPage ||
              isOnSelectImagesPage ||
              isOnPaymentPage ||
              isOnCheckoutPage)) {
        return '/login';
      }

      // Root route redirects based on auth state
      if (state.matchedLocation == '/') {
        return isAuthenticated ? '/home' : '/login';
      }

      return null;
    },
    refreshListenable: _AuthNotifierListenable(ref),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final authState = ref.read(authNotifierProvider);
          return authState.isAuthenticated ? '/home' : '/login';
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/otp-verification',
        name: 'otp-verification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          final source = extra?['source'] as String? ?? 'forgot_password';
          return OtpVerificationPage(email: email, source: source);
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          final otp = extra?['otp'] as String? ?? '';
          return ResetPasswordPage(email: email, otp: otp);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialTabIndex = extra?['initialTabIndex'] as int?;
          return HomePage(initialTabIndex: initialTabIndex);
        },
      ),
      GoRoute(
        path: '/pricing/:id',
        name: 'pricing',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PricingPage(id: id);
        },
      ),
      GoRoute(
        path: '/select-images',
        name: 'select-images',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            // Fallback if no data provided
            return const SelectImagesPage(
              pricingPlanId: '',
              basePrice: 0.0,
              hasDecluttering: false,
              declutteringPrice: 0.0,
              totalPrice: 0.0,
              maxImages: 0,
            );
          }
          final selectedOptionalFeatures =
              extra['selectedOptionalFeatures'] as List<dynamic>?;
          List<Map<String, dynamic>>? optionalFeaturesList;
          if (selectedOptionalFeatures != null) {
            optionalFeaturesList = selectedOptionalFeatures
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
          return SelectImagesPage(
            pricingPlanId: extra['pricingPlanId'] as String? ?? '',
            basePrice: (extra['basePrice'] as num?)?.toDouble() ?? 0.0,
            hasDecluttering: extra['hasDecluttering'] as bool? ?? false,
            declutteringPrice:
                (extra['declutteringPrice'] as num?)?.toDouble() ?? 0.0,
            totalPrice: (extra['totalPrice'] as num?)?.toDouble() ?? 0.0,
            maxImages: extra['maxImages'] as int? ?? 0,
            selectedOptionalFeatures: optionalFeaturesList,
          );
        },
      ),
      GoRoute(
        path: '/payment',
        name: 'payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            // Fallback if no data provided
            return const OrderSummaryPage(
              pricingPlanId: '',
              basePrice: 0.0,
              hasDecluttering: false,
              declutteringPrice: 0.0,
              totalPrice: 0.0,
              selectedImagePaths: null,
              selectedOptionalFeatures: null,
            );
          }
          // Extract selected image paths if available
          final selectedImagePaths =
              extra['selectedImagePaths'] as List<dynamic>?;
          List<String>? imagePathsList;
          if (selectedImagePaths != null) {
            imagePathsList = selectedImagePaths.cast<String>();
          }
          final selectedOptionalFeatures =
              extra['selectedOptionalFeatures'] as List<dynamic>?;
          List<Map<String, dynamic>>? optionalFeaturesList;
          if (selectedOptionalFeatures != null) {
            optionalFeaturesList = selectedOptionalFeatures
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }

          return OrderSummaryPage(
            pricingPlanId: extra['pricingPlanId'] as String? ?? '',
            basePrice: (extra['basePrice'] as num?)?.toDouble() ?? 0.0,
            hasDecluttering: extra['hasDecluttering'] as bool? ?? false,
            declutteringPrice:
                (extra['declutteringPrice'] as num?)?.toDouble() ?? 0.0,
            totalPrice: (extra['totalPrice'] as num?)?.toDouble() ?? 0.0,
            selectedImagePaths: imagePathsList,
            selectedOptionalFeatures: optionalFeaturesList,
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            // Fallback if no data provided
            return const CheckoutWebViewPage(sessionUrl: '', sessionId: '');
          }
          return CheckoutWebViewPage(
            sessionUrl: extra['sessionUrl'] as String? ?? '',
            sessionId: extra['sessionId'] as String? ?? '',
          );
        },
      ),
    ],
  );
});

/// Listenable wrapper for auth notifier to enable router refresh
/// Only refreshes router on authentication state changes, not on loading or registration state changes
class _AuthNotifierListenable extends Listenable {
  final Ref _ref;

  _AuthNotifierListenable(this._ref);

  @override
  void addListener(VoidCallback listener) {
    // Listen to auth state changes and notify the router
    _ref.listen(authNotifierProvider, (previous, next) {
      // Only trigger router refresh on actual authentication state changes
      // Skip router refresh for:
      // 1. Loading state changes (isLoading)
      // 2. Error state changes (error)
      // 3. Registration state changes (user set but not authenticated)
      // Only refresh when isAuthenticated actually changes
      final authChanged = previous?.isAuthenticated != next.isAuthenticated;

      if (authChanged) {
        listener();
      }
    });
  }

  @override
  void removeListener(VoidCallback listener) {
    // No-op: Riverpod doesn't support removing listeners this way
    // The router will handle cleanup automatically
  }
}
