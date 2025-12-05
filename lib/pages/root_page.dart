import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/login_page.dart';
import 'home/home_page.dart';
import '../providers/auth_provider.dart';

class RootPage extends ConsumerWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    // Navigate based on authentication status
    if (authState.isAuthenticated) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}
