import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/register_page.dart';
import '../../pages/home/home_page.dart';
import '../../pages/pricing/pricing_page.dart';
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

      // If still loading auth state, don't redirect yet
      if (authState.isLoading) {
        return null;
      }

      // If authenticated and trying to access auth pages, redirect to home
      if (isAuthenticated && (isOnLoginPage || isOnRegisterPage)) {
        return '/home';
      }

      // If not authenticated and trying to access protected pages, redirect to login
      if (!isAuthenticated && (isOnHomePage || isOnPricingPage)) {
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
