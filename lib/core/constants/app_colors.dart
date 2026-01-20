import 'package:flutter/material.dart';

class AppColors {
  // Main Brand Colors
  static const Color primary = Color(0xFF00695C); // Deep Teal
  static const Color primaryLight = Color(0xFFB2DFDB); // Light Teal
  static const Color accent = Color(0xFF1976D2); // Blue

  // Status Colors ( for Triage/Emergency)
  static const Color success = Color(0xFF4CAF50); // Green (Stable)
  static const Color warning = Color(0xFFFFC107); // Amber (Minor)
  static const Color danger = Color(0xFFD32F2F); // Red (Critical/Emergency)
  static const Color info = Color(0xFF1976D2); // Blue (Telemed)

  // Neutral Colors
  static const Color background = Color(0xFFF8F9FA); // Off-white background
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color iconColor = Color(0xFF666666);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00695C), Color(0xFF004D40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}