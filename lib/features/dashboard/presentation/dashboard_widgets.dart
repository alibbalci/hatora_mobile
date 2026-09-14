import 'package:flutter/material.dart';

import '../../../core/design/app_stat_card.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/dashboard_models.dart';

String examCountdownLabel(int? daysUntilExam) {
  if (daysUntilExam == null) return 'Sınav tarihi belirtilmemiş';
  if (daysUntilExam > 0) return '$daysUntilExam gün kaldı';
  if (daysUntilExam == 0) return 'Bugün';
  return 'Sınav tarihi geçti';
}

String reviewCtaLabel(DashboardReviewSummary review) {
  if (review.hasActiveReviewSession) return 'Tekrara Devam Et';
  if (review.dueCount > 0) return 'Tekrara Başla';
  return 'Bugünlük tekrarın yok';
}

class DashboardActiveExamCard extends StatelessWidget {
  const DashboardActiveExamCard({super.key, required this.exam});
  final DashboardActiveExam exam;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: AppRadius.lgAll,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.accent, AppColors.accentEnd],
      ),
    ),
    child: Stack(
      children: [
        Positioned(right: -30, top: -30, child: _decorativeCircle(96, 0.14)),
        Positioned(right: 30, bottom: -46, child: _decorativeCircle(70, 0.10)),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: AppColors.surface,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: AppRadius.smAll,
                        ),
                        child: Text(
                          examCountdownLabel(exam.daysUntilExam),
                          style: AppTypography.heroSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                exam.examName,
                style: AppTypography.heroTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${exam.examYear} dönemi',
                style: AppTypography.heroSubtitle,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _decorativeCircle(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

class DashboardReviewProgressCard extends StatelessWidget {
  const DashboardReviewProgressCard({super.key, required this.review});
  final DashboardReviewSummary review;
  @override
  Widget build(BuildContext context) {
    final zero = review.effectiveReviewGoal == 0;
    final ratio = zero
        ? 0.0
        : (review.reviewsCompletedToday / review.effectiveReviewGoal).clamp(
            0.0,
            1.0,
          );
    return Card(
      color: review.goalCompleted ? AppColors.successSoft : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  review.goalCompleted
                      ? Icons.check_circle_rounded
                      : Icons.today_outlined,
                  color: review.goalCompleted
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
                  '${review.reviewsCompletedToday} / ${review.effectiveReviewGoal}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            if (zero)
              Text(
                'Bugün için bir hedef atanmadı, dinlenebilirsin.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: ratio, minHeight: 8),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                review.goalCompleted
                    ? 'Bugünkü hedef tamamlandı.'
                    : 'Hedefine devam et.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DashboardStatGrid extends StatelessWidget {
  const DashboardStatGrid({
    super.key,
    required this.progress,
    required this.questions,
  });
  final DashboardProgressSummary progress;
  final DashboardQuestionSummary questions;
  @override
  Widget build(BuildContext context) => AppStatGrid(
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
      AppStatCard(
        icon: Icons.auto_stories_outlined,
        value: '${questions.activeCount}',
        label: 'Aktif soru',
        color: AppColors.accent,
      ),
      AppStatCard(
        icon: Icons.emoji_events_outlined,
        value: '${questions.masteredCount}',
        label: 'Öğrenilen',
        color: AppColors.success,
      ),
    ],
  );
}
