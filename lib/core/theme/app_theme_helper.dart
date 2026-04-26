import 'package:flutter/material.dart';

class AppThemeHelper {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color background(BuildContext context) {
    return isDark(context) 
      ? const Color(0xFF0F172A) 
      : const Color(0xFFF5F5F7);
  }

  static Color surface(BuildContext context) {
    return isDark(context) 
      ? const Color(0xFF1E293B) 
      : const Color(0xFFFFFFFF);
  }

  static Color card(BuildContext context) {
    return isDark(context) 
      ? const Color(0xFF334155) 
      : const Color(0xFFFFFFFF);
  }

  static Color textPrimary(BuildContext context) {
    return isDark(context) 
      ? const Color(0xFFF8FAFC) 
      : const Color(0xFF1E293B);
  }

  static Color textSecondary(BuildContext context) {
    return isDark(context) 
      ? const Color(0xFF94A3B8) 
      : const Color(0xFF64748B);
  }

  static Color divider(BuildContext context) {
    return isDark(context) 
      ? const Color(0xFF475569) 
      : const Color(0xFFE2E8F0);
  }
}
