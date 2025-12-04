import 'package:flutter/material.dart';

/// App color constants for the photography app
/// Uses a modern, elegant color palette suitable for a photography service
class AppColors {
  AppColors._();

  // Primary colors - Deep, professional tones
  static const Color primary = Color(0xFF1A1A2E); // Deep navy/charcoal
  static const Color primaryDark = Color(0xFF0F0F1E); // Almost black
  static const Color primaryLight = Color(0xFF2D2D44); // Lighter navy

  // Accent colors - Warm, inviting tones
  static const Color accent = Color(0xFFFF6B6B); // Coral red
  static const Color accentLight = Color(0xFFFF8E8E); // Light coral
  static const Color accentDark = Color(0xFFE55555); // Dark coral

  // Secondary colors - Complementary tones
  static const Color secondary = Color(0xFF4ECDC4); // Teal/turquoise
  static const Color secondaryLight = Color(0xFF6EDDD6); // Light teal
  static const Color secondaryDark = Color(0xFF3BA8A1); // Dark teal

  // Background colors
  static const Color background = Color(0xFFF8F9FA); // Off-white
  static const Color backgroundDark = Color(0xFF1A1A2E); // Dark background
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceDark = Color(0xFF2D2D44); // Dark surface

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E); // Dark text
  static const Color textSecondary = Color(0xFF6C757D); // Gray text
  static const Color textLight = Color(0xFFFFFFFF); // White text
  static const Color textHint = Color(0xFFADB5BD); // Hint text

  // Border and divider colors
  static const Color border = Color(0xFFE0E0E0); // Light border
  static const Color borderDark = Color(0xFF3D3D5C); // Dark border
  static const Color divider = Color(0xFFE9ECEF); // Divider

  // Status colors
  static const Color success = Color(0xFF28A745); // Green
  static const Color error = Color(0xFFDC3545); // Red
  static const Color warning = Color(0xFFFFC107); // Yellow
  static const Color info = Color(0xFF17A2B8); // Blue

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF2D2D44),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B6B),
      Color(0xFFFF8E8E),
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8F9FA),
      Color(0xFFFFFFFF),
    ],
  );
}

