import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../dashboard/domain/dashboard_models.dart';

String homeDateLabel(DateTime date) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  const days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  return '${date.day} ${months[date.month - 1]}, ${days[date.weekday - 1]}';
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    required this.today,
    required this.streak,
    required this.onProfile,
  });
  final String name;
  final DateTime today;
  final int streak;
  final VoidCallback onProfile;
  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? 'H'
        : words
              .take(2)
              .map((s) => String.fromCharCode(s.runes.first))
              .join()
              .toUpperCase();
    final badge = Tooltip(
      message: '$streak günlük çalışma serisi',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 17,
              color: AppColors.warning,
            ),
            const SizedBox(width: 5),
            Text(
              '$streak',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryInk,
              ),
            ),
          ],
        ),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Profili aç',
          child: InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(28),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.accentSoft,
              foregroundColor: AppColors.accent,
              child: Text(initials),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                homeDateLabel(today),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Merhaba, ${words.isEmpty ? '' : words.first}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (MediaQuery.textScalerOf(context).scale(14) > 18)
                Padding(padding: const EdgeInsets.only(top: 6), child: badge),
            ],
          ),
        ),
        if (MediaQuery.textScalerOf(context).scale(14) <= 18) badge,
      ],
    );
  }
}

class HomeWeekActivity extends StatelessWidget {
  const HomeWeekActivity({super.key, required this.study});
  final DashboardStudySummary study;
  @override
  Widget build(BuildContext context) {
    const labels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
    final active = study.weekDays
        .where((d) => d.active && !d.date.isAfter(study.today))
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bu hafta',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$active / 7 gün',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, c) => Wrap(
                spacing: 8,
                runSpacing: 12,
                children: study.weekDays.map((day) {
                  final today =
                      day.date.year == study.today.year &&
                      day.date.month == study.today.month &&
                      day.date.day == study.today.day;
                  final worked = day.active && !day.date.isAfter(study.today);
                  final size = MediaQuery.textScalerOf(context).scale(14) > 18
                      ? 48.0
                      : (c.maxWidth - 48) / 7;
                  return Semantics(
                    label:
                        '${homeDateLabel(day.date)}: ${worked ? 'çalışıldı' : 'çalışma kaydı yok'}',
                    child: ExcludeSemantics(
                      child: SizedBox(
                        width: size,
                        child: Column(
                          children: [
                            Container(
                              height: size,
                              width: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: worked
                                    ? AppColors.accent
                                    : AppColors.surfaceMuted,
                                border: today
                                    ? Border.all(
                                        color: AppColors.accent,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: worked
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.surface,
                                      size: 18,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              labels[day.date.weekday - 1],
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: today
                                        ? AppColors.accent
                                        : AppColors.secondaryText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onAdd,
    required this.onPlan,
    this.study,
  });
  final VoidCallback onAdd, onPlan;
  final DashboardStudySummary? study;
  @override
  Widget build(BuildContext context) {
    Widget action(
      String title,
      String subtitle,
      IconData icon,
      bool primary,
      VoidCallback onTap,
    ) => SizedBox(
      height:
          106 +
          MediaQuery.textScalerOf(context).scale(24) * 2 +
          MediaQuery.textScalerOf(context).scale(18) * 2,
      child: Material(
        color: primary ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary
                        ? AppColors.surface.withValues(alpha: .18)
                        : AppColors.successSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: primary ? AppColors.surface : AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: primary ? AppColors.surface : AppColors.primaryInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: primary
                        ? AppColors.surface.withValues(alpha: .75)
                        : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final subtitle = study == null
        ? 'Tekrarlarını gör'
        : study!.tomorrowTopicCount > 0
        ? 'Yarın ${study!.tomorrowTopicCount} konu'
        : 'Yarın planlı tekrar yok';
    return LayoutBuilder(
      builder: (context, c) {
        final add = action(
          'Yeni soru ekle',
          'Fotoğrafla, kaydet',
          Icons.add_a_photo_outlined,
          true,
          onAdd,
        );
        final plan = action(
          'Planıma bak',
          subtitle,
          Icons.event_note_outlined,
          false,
          onPlan,
        );
        if (c.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [add, const SizedBox(height: 12), plan],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: add),
            const SizedBox(width: 12),
            Expanded(child: plan),
          ],
        );
      },
    );
  }
}
