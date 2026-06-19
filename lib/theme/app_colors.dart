import 'package:flutter/material.dart';
import '../config/app_config.dart';

class AppColors {
  AppColors._();

  static bool get _isDark {
    try {
      return AppConfig.darkTheme;
    } catch (_) {
      return true; // Fallback before instance is set
    }
  }

  static Color get background => _isDark ? const Color(0xFF000000) : const Color(0xFFF3F4F6);
  static Color get surface => _isDark ? const Color(0xFF0A0A1A) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt => _isDark ? const Color(0xFF0D0D1F) : const Color(0xFFF9FAFB);
  
  static Color get border => _isDark ? const Color(0xFF2A2A4A) : const Color(0xFFD1D5DB);
  static Color get borderSubtle => _isDark ? const Color(0xFF1A1A3A) : const Color(0xFFE5E7EB);
  
  static const accentBlue = Color(0xFF3B6FE8);
  static const primary = accentBlue;
  static const accentPurple = Color(0xFF8B5FE8);
  
  static Color get textPrimary => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
  static Color get textSecondary => _isDark ? const Color(0xFF888899) : const Color(0xFF6B7280);
  static Color get textMuted => _isDark ? const Color(0xFF555577) : const Color(0xFF9CA3AF);
  
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFEAB308);
  static const error = Color(0xFFEF4444);
  static Color get neutralIcon => _isDark ? const Color(0xFFCCCCDD) : const Color(0xFF9CA3AF);

  /// Reusable glow BoxShadow helper.
  static BoxShadow glow(Color color, {double blur = 24}) => BoxShadow(
        color: color.withValues(alpha: 0.35),
        blurRadius: blur,
        spreadRadius: 0,
      );
}
