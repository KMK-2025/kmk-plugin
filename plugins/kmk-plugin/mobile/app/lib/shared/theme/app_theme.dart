import 'package:flutter/material.dart';

/// رموز التصميم — المصدر الوحيد للألوان والمسافات في التطبيق.
/// تُملأ من docs/design-system.md لتطابق الموقع. ممنوع لون أو مسافة
/// مكتوبة مباشرة داخل شاشة.
abstract final class AppColors {
  static const Color primary = Color(0xFF0D6EFD);
  static const Color danger = Color(0xFFDC3545);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        error: AppColors.danger,
      ),
    );
  }
}
