import 'package:flutter/material.dart';

class AppPalette {
  final Brightness brightness;
  final Color primary;
  final Color sidebar;
  final Color accent;
  final Color onPrimary;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color borderOutline;
  final Color divider;
  final Color success;
  final Color successBg;
  final Color error;
  final Color errorBg;
  final Color primaryBg;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.sidebar,
    required this.accent,
    required this.onPrimary,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.borderOutline,
    required this.divider,
    required this.success,
    required this.successBg,
    required this.error,
    required this.errorBg,
    required this.primaryBg,
  });

  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF6458F5),
    sidebar: Color(0xFF4848AD),
    accent: Color(0xFF5CCBBA),
    onPrimary: Color(0xFFFFFFFF),
    background: Color(0xFFFCFBFF),
    textPrimary: Color(0xFF1E1E1E),
    textSecondary: Color(0xFF0A090B),
    textHint: Color(0xFFA3A3A3),
    borderOutline: Color(0xffD0D0FD),
    divider: Color(0xffE5E7EB),
    success: Color(0xFF22C55E),
    successBg: Color(0xFFEFFFF5),
    error: Color(0xFFEF4444),
    errorBg: Color(0xFFFFF1F1),
    primaryBg: Color(0xFFF3EFFF),
  );
}
