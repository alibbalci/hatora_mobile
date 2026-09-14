import 'package:flutter/material.dart';

import 'app_theme.dart';

/// TR: `Theme.of(context).textTheme` yeterli olmadığı birkaç özel durum için
/// (büyük metrik rakamlar, hero başlıklar) küçük, isimlendirilmiş stiller.
/// Ekranların çoğu doğrudan [ThemeData.textTheme] kullanmaya devam eder.
/// EN: A few named styles for the rare cases `Theme.of(context).textTheme`
/// isn't enough (large metric numbers, hero titles). Most screens keep using
/// [ThemeData.textTheme] directly.
abstract final class AppTypography {
  static const heroTitle = TextStyle(
    color: AppColors.surface,
    fontWeight: FontWeight.w800,
    fontSize: 24,
    height: 1.15,
  );
  static const heroSubtitle = TextStyle(
    color: AppColors.surface,
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );
  static const metricValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryInk,
  );
  static const metricLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.secondaryText,
  );
}
