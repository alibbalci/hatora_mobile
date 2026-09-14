import 'package:flutter/material.dart';

import 'app_radius.dart';
import 'app_spacing.dart';

/// TR: Hatora'nın tek marka paleti — koyu indigo/lacivert ailesi, yumuşak
/// nötr yüzeyler ve kısıtlı bir vurgu rengi. Her ekran bu semantik
/// token'ları kullanır; hiçbir dosyada serbest hex renk yoktur.
/// EN: Hatora's single brand palette — a deep indigo/navy family, soft
/// neutral surfaces, and one restrained accent. Every screen uses these
/// semantic tokens; no file has a loose hex color.
abstract final class AppColors {
  // Neutral surfaces
  static const background = Color(0xFFF6F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F2F8);
  static const line = Color(0xFFE4E6F0);

  // Text
  static const primaryInk = Color(0xFF1E1B4B);
  static const secondaryText = Color(0xFF64748B);

  // Brand — deep indigo / blue-violet
  static const accent = Color(0xFF4F46E5);
  static const accentEnd = Color(0xFF7C3AED);
  static const accentSoft = Color(0xFFEEF0FD);

  // Semantic status
  static const success = Color(0xFF1F9D6B);
  static const successSoft = Color(0xFFE5F6EE);
  static const warning = Color(0xFFDB9A2C);
  static const warningSoft = Color(0xFFFBF1DF);
  static const error = Color(0xFFDC5B62);
  static const errorSoft = Color(0xFFFBEAEB);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      primary: AppColors.accent,
      onPrimary: AppColors.surface,
      secondary: AppColors.accentEnd,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
  );
  final textTheme = base.textTheme
      .apply(
        bodyColor: AppColors.primaryInk,
        displayColor: AppColors.primaryInk,
      )
      .copyWith(
        displaySmall: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.15,
          color: AppColors.primaryInk,
        ),
        headlineMedium: const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: AppColors.primaryInk,
        ),
        headlineSmall: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: AppColors.primaryInk,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryInk,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryInk,
        ),
        titleSmall: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryInk,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: AppColors.primaryInk,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: AppColors.primaryInk,
        ),
        bodySmall: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: AppColors.secondaryText,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryInk,
        ),
        labelMedium: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryText,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryText,
        ),
      );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.primaryInk,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.primaryInk,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: AppColors.primaryInk),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.base,
      ),
      hintStyle: const TextStyle(color: AppColors.secondaryText),
      labelStyle: const TextStyle(color: AppColors.secondaryText),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.error, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.secondaryText,
        minimumSize: const Size(double.infinity, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryInk,
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: AppColors.line),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.primaryInk),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceMuted,
      selectedColor: AppColors.accentSoft,
      disabledColor: AppColors.surfaceMuted,
      labelStyle: const TextStyle(
        color: AppColors.primaryInk,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.accent,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accentSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.secondaryText,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.secondaryText,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: AppColors.line,
      circularTrackColor: AppColors.line,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primaryInk,
      contentTextStyle: const TextStyle(color: AppColors.surface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      iconColor: AppColors.accent,
    ),
    // TR: Geriye dönük uyumluluk — eski BottomNavigationBar kullanılan
    // yerler için; asıl uygulama artık NavigationBar kullanır.
    // EN: Backward compatibility for any lingering BottomNavigationBar use;
    // the app itself now uses NavigationBar.
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.secondaryText,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 10),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
  );
}
