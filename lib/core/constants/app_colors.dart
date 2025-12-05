import 'package:flutter/material.dart';

/// App color constants for the photography app
/// Uses colors from the app logo design
class AppColors {
  AppColors._();

  // Logo colors
  static const Color vibrantGreen = Color(0xFF56AD43);
  static const Color white = Color(0xFFFBFCFC);
  static const Color tealAqua = Color(0xFF09A087);
  static const Color lightTurquoise = Color(0xFF91CFC5);
  static const Color darkShadow = Color(0xFF1C221D);

  // Primary colors - Using vibrant green as primary
  static const Color primary = vibrantGreen; // #56AD43
  static const Color primaryDark = Color(0xFF459A35); // Darker green
  static const Color primaryLight = Color(0xFF6BC058); // Lighter green

  // Secondary colors - Teal/aqua tones
  static const Color secondary = tealAqua; // #09A087
  static const Color secondaryLight = lightTurquoise; // #91CFC5
  static const Color secondaryDark = Color(0xFF078A75); // Darker teal

  // Background colors
  static const Color background = white; // #FBFCFC
  static const Color backgroundDark = darkShadow; // #1C221D
  static const Color surface = white; // #FBFCFC
  static const Color surfaceDark = Color(0xFF2A332C); // Dark surface

  // Text colors
  static const Color textPrimary = darkShadow; // #1C221D
  static const Color textSecondary = Color(0xFF6C757D); // Gray text
  static const Color textLight = white; // #FBFCFC
  static const Color textHint = Color(0xFFADB5BD); // Hint text

  // Border and divider colors
  static const Color border = Color(0xFFE0E0E0); // Light border
  static const Color borderDark = Color(0xFF3D3D5C); // Dark border
  static const Color divider = Color(0xFFE9ECEF); // Divider

  // Status colors
  static const Color success = vibrantGreen; // #56AD43
  static const Color error = Color(0xFFDC3545); // Red
  static const Color warning = Color(0xFFFFC107); // Yellow
  static const Color info = tealAqua; // #09A087

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      lightTurquoise, // #91CFC5 - upper highlight
      vibrantGreen, // #56AD43 - bottom-right accent
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [vibrantGreen, primaryLight],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      lightTurquoise, // #91CFC5 - upper highlight
      tealAqua, // #09A087 - main background
    ],
  );
}
