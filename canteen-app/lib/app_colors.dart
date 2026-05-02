import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF944A00);
  static const Color primaryLight = Color(0xFFE67E22);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF944A00), Color(0xFFE67E22)],
  );

  // Background
  static const Color background = Color(0xFFFBF9F4);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF5F3EE);

  // Text
  static const Color textDark = Color(0xFF1B1C19);
  static const Color textMuted = Color(0xFF564337);
  static const Color textLight = Color(0xFF897365);
  static const Color textDisabled = Color(0xFFA8A29E);

  // Status
  static const Color success = Color(0xFF1A6B4A);
  static const Color notice = Color(0xFF1C0062);
  static const Color noticeBackground = Color(0xFFE6DEFF);

  // Border
  static const Color border = Color(0xFFDCC1B1);

  // Tag colors
  static const Color tagBackground = Color(0xFFF5F3EE);
  static const Color tagText = Color(0xFF564337);
}
