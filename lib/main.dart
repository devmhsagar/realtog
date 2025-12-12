import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:realtog/core/router/app_router.dart';
import 'package:realtog/core/theme/theme.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Google Sign-In once at app startup
  // On iOS, explicitly pass the clientId from Firebase options
  // On Android, it will be read from google-services.json
  await GoogleSignIn.instance.initialize(
    clientId: Platform.isIOS ? DefaultFirebaseOptions.ios.iosClientId : null,
  );

  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'RealTog',
          theme: AppTheme.lightTheme,
          routerConfig: router,
        );
      },
    );
  }
}
