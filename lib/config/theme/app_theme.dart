import 'package:flutter/material.dart';

abstract final class AppColors {
  static const fieBlue = Color(0xFF0D3B66);
  static const fieBlueDark = Color(0xFF092C4D);
  static const gold = Color(0xFFF4D35E);
  static const ink = Color(0xFF25242A);
  static const muted = Color(0xFF77747A);
  static const canvas = Color(0xFFF7F5F2);
  static const line = Color(0xFFEAE6E1);
  static const green = Color(0xFF25815B);
  static const yellow = Color(0xFFB7790A);
  static const red = Color(0xFFC63F43);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.fieBlue,
      primary: AppColors.fieBlue,
      secondary: AppColors.gold,
      surface: Colors.white,
      error: AppColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: AppColors.ink, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          height: 1.35,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.fieBlue, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.fieBlue.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
    );
  }

  static ThemeData get dark {
    const surface = Color(0xFF18232F);
    const canvas = Color(0xFF101820);
    const onSurface = Color(0xFFE7EDF3);
    const outline = Color(0xFF3B4A59);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.fieBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF78B9E8),
          onPrimary: const Color(0xFF081724),
          secondary: AppColors.gold,
          surface: surface,
          onSurface: onSurface,
          error: const Color(0xFFFF7A7A),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fieBlue,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: onSurface, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(
          color: Color(0xFFADB9C5),
          fontSize: 12,
          height: 1.35,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF202D3A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF78B9E8), width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF151F2B),
        indicatorColor: const Color(0xFF78B9E8).withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? onSurface
                : const Color(0xFFADB9C5),
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: surface),
    );
  }
}

abstract final class AppSettings {
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static final pushNotifications = ValueNotifier<bool>(true);
  static final maintenanceAlerts = ValueNotifier<bool>(true);
}
