import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// TR: 2 sütunlu metrik ızgaralarında kullanılan tek bir istatistik karosu
/// (Home/Statistics). Değer + etiket + ikon; renk yalnızca vurgu içindir,
/// tek başına bir durumu ifade etmez.
/// EN: One metric tile used in the 2-column stat grids on Home/Statistics.
/// Value + label + icon; color is decorative accent only, never the sole
/// state signal.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.accent,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.base),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

/// TR: Karoları eşit genişlikte, sarılabilir bir ızgaraya yerleştirir.
/// EN: Lays tiles out in an equal-width, wrapping grid.
class AppStatGrid extends StatelessWidget {
  const AppStatGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = AppSpacing.md;
      final columns = constraints.maxWidth < 360 ? 2 : 2;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
