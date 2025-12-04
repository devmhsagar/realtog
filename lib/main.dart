import 'package:flutter/material.dart';
import 'package:realtog/pages/auth/login_page.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(child: LoginPage()),
    );
  }
}
