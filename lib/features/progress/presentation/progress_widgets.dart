import 'package:flutter/material.dart';

import '../../../core/design/app_stat_card.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/progress_models.dart';

class ProgressOverview extends StatelessWidget {
  const ProgressOverview({super.key, required this.progress});
  final UserProgress progress;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppStatGrid(
        children: [
          AppStatCard(
            icon: Icons.bolt_rounded,
            value: '${progress.totalXp} XP',
            label: 'Seviye ${progress.level}',
            color: AppColors.warning,
          ),
          AppStatCard(
            icon: Icons.local_fire_department_rounded,
            value: '${progress.currentStreak} gün',
            label: 'En uzun: ${progress.longestStreak} gün',
            color: AppColors.error,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      TodayProgressCard(progress: progress.today),
    ],
  );
}

class TodayProgressCard extends StatelessWidget {
  const TodayProgressCard({super.key, required this.progress});
  final DailyProgress progress;
  @override
  Widget build(BuildContext context) {
    final zero = progress.effectiveReviewGoal == 0;
    final ratio = zero
        ? 0.0
        : (progress.reviewsCompleted / progress.effectiveReviewGoal).clamp(
            0.0,
            1.0,
          );
    return Card(
      color: progress.goalCompleted ? AppColors.successSoft : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  progress.goalCompleted
                      ? Icons.check_circle_rounded
                      : Icons.today_outlined,
                  color: progress.goalCompleted
                      ? AppColors.success
                      : AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Bugünkü tekrarlar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${progress.reviewsCompleted} / ${progress.effectiveReviewGoal}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            if (zero)
              Text(
                'Bugün tekrar bekleyen sorun yok.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: ratio, minHeight: 8),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                progress.goalCompleted
                    ? 'Bugünkü hedef tamamlandı.'
                    : 'Hedefine devam et.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                _metaText(context, 'Doğru ${progress.correctCount}'),
                _metaText(context, 'Yanlış ${progress.wrongCount}'),
                _metaText(context, 'Boş ${progress.unsolvedCount}'),
                _metaText(context, 'Öğrenilen ${progress.questionsMastered}'),
                _metaText(context, 'Bugün +${progress.xpEarned} XP'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaText(BuildContext context, String text) =>
      Text(text, style: Theme.of(context).textTheme.labelMedium);
}
