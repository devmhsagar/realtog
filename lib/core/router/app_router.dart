import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/register_page.dart';
import '../../pages/home/home_page.dart';
import '../../pages/pricing/pricing_page.dart';
import '../../pages/select_images/select_images_page.dart';
import '../../pages/order_summary/order_summary_page.dart';
import '../../providers/auth_provider.dart';

/// Router configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state to trigger router rebuilds
  ref.watch(authNotifierProvider);

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

      // If still loading auth state, don't redirect yet
      if (authState.isLoading) {
        return null;
      }

      // If authenticated and trying to access auth pages, redirect to home
      if (isAuthenticated && (isOnLoginPage || isOnRegisterPage)) {
        return '/home';
      }

      // If not authenticated and trying to access protected pages, redirect to login
      if (!isAuthenticated &&
          (isOnHomePage ||
              isOnPricingPage ||
              isOnSelectImagesPage ||
              isOnPaymentPage)) {
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
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
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
              basePrice: 0,
              hasDecluttering: false,
              declutteringPrice: 0,
              totalPrice: 0,
              maxImages: 0,
            );
          }
          return SelectImagesPage(
            pricingPlanId: extra['pricingPlanId'] as String? ?? '',
            basePrice: extra['basePrice'] as int? ?? 0,
            hasDecluttering: extra['hasDecluttering'] as bool? ?? false,
            declutteringPrice: extra['declutteringPrice'] as int? ?? 0,
            totalPrice: extra['totalPrice'] as int? ?? 0,
            maxImages: extra['maxImages'] as int? ?? 0,
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
              basePrice: 0,
              hasDecluttering: false,
              declutteringPrice: 0,
              totalPrice: 0,
              selectedImagePaths: null,
            );
          }
          // Extract selected image paths if available
          final selectedImagePaths =
              extra['selectedImagePaths'] as List<dynamic>?;
          List<String>? imagePathsList;
          if (selectedImagePaths != null) {
            imagePathsList = selectedImagePaths.cast<String>();
          }

          return OrderSummaryPage(
            pricingPlanId: extra['pricingPlanId'] as String? ?? '',
            basePrice: extra['basePrice'] as int? ?? 0,
            hasDecluttering: extra['hasDecluttering'] as bool? ?? false,
            declutteringPrice: extra['declutteringPrice'] as int? ?? 0,
            totalPrice: extra['totalPrice'] as int? ?? 0,
            selectedImagePaths: imagePathsList,
          );
        },
      ),
    ],
  );
});

/// Listenable wrapper for auth notifier to enable router refresh
class _AuthNotifierListenable extends Listenable {
  final Ref _ref;

  _AuthNotifierListenable(this._ref);

  @override
  void addListener(VoidCallback listener) {
    // Listen to auth state changes and notify the router
    _ref.listen(authNotifierProvider, (previous, next) {
      listener();
    });
  }

  @override
  void removeListener(VoidCallback listener) {
    // No-op: Riverpod doesn't support removing listeners this way
    // The router will handle cleanup automatically
  }
}
