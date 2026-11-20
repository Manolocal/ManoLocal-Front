import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Configuración centralizada de temas Material 3 para ManoLocal.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.yellow,
      onPrimary: AppColors.gray,
      primaryContainer: AppColors.yellowSoft,
      onPrimaryContainer: AppColors.gray,
      secondary: AppColors.gray,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.silver,
      onSecondaryContainer: AppColors.gray,
      surface: AppColors.white,
      onSurface: AppColors.gray,
      onSurfaceVariant: AppColors.grayMuted,
      surfaceContainerHighest: AppColors.silver,
      outline: AppColors.silver,
      outlineVariant: AppColors.silver,
      error: AppColors.error,
      onError: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.gray,
        foregroundColor: AppColors.white,
        iconTheme: IconThemeData(color: AppColors.yellow),
        actionsIconTheme: IconThemeData(color: AppColors.yellow),
        centerTitle: false,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.gray,
          disabledBackgroundColor: AppColors.silver,
          disabledForegroundColor: AppColors.grayMuted,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gray,
          side: const BorderSide(color: AppColors.gray, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        prefixIconColor: AppColors.grayMuted,
        suffixIconColor: AppColors.grayMuted,
        labelStyle: const TextStyle(color: AppColors.grayMuted),
        hintStyle: const TextStyle(color: AppColors.grayMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.silver),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.silver),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.yellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.silver),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.silver,
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.yellow,
      onPrimary: AppColors.gray,
      primaryContainer: AppColors.yellowDark,
      onPrimaryContainer: AppColors.grayDark,
      secondary: AppColors.silver,
      onSecondary: AppColors.grayDark,
      secondaryContainer: AppColors.graySurface,
      onSecondaryContainer: AppColors.silver,
      surface: AppColors.gray,
      onSurface: AppColors.white,
      onSurfaceVariant: AppColors.silver,
      surfaceContainerHighest: AppColors.graySurface,
      outline: AppColors.grayMuted,
      outlineVariant: AppColors.graySurface,
      error: AppColors.error,
      onError: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.grayDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.gray,
        foregroundColor: AppColors.white,
        iconTheme: IconThemeData(color: AppColors.yellow),
        actionsIconTheme: IconThemeData(color: AppColors.yellow),
        centerTitle: false,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.gray,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.silver,
          side: const BorderSide(color: AppColors.silver, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.graySurface,
        prefixIconColor: AppColors.silver,
        suffixIconColor: AppColors.silver,
        labelStyle: const TextStyle(color: AppColors.silver),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grayMuted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grayMuted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.yellow, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.gray,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.graySurface),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.graySurface,
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
