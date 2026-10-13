import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../dashboard/domain/dashboard_models.dart';

class HomeFocusCard extends StatelessWidget {
  const HomeFocusCard({
    super.key,
    required this.review,
    required this.hasQuestions,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.questionCount,
  });
  final DashboardReviewSummary review;
  final int? questionCount;
  final bool hasQuestions, busy;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final completed = review.goalCompleted && review.reviewsCompletedToday > 0;
    final remaining =
        (review.effectiveReviewGoal - review.reviewsCompletedToday).clamp(
          0,
          review.dueCount,
        );
    final title = review.hasActiveReviewSession
        ? 'Kaldığın yerden\ndevam edelim.'
        : completed
        ? 'Bugünkü hedefin\ntamamlandı.'
        : review.dueCount > 0
        ? (remaining > 0
              ? 'Bugün $remaining soruyla\nbir adım daha.'
              : 'Bir tekrar,\nbir adım daha.')
        : hasQuestions
        ? 'Bugünlük tamam.\nBir nefes al.'
        : 'İlk soruyla\nbaşlayalım.';
    final subtitle = review.hasActiveReviewSession
        ? 'Başladığın tekrar seni bekliyor. Küçük bir adım daha atabilirsin.'
        : completed
        ? 'Kendine verdiğin sözü tuttun. İstersen bekleyen sorularla devam edebilirsin.'
        : review.dueCount > 0
        ? 'Zorlandığın sorulara yeniden bak. Her tekrar, sınavına bir hazırlık.'
        : hasQuestions
        ? 'Tekrar zamanı gelen soruların burada seni bekleyecek.'
        : 'Zorlandığın bir sorunun fotoğrafını ekle. Birlikte tekrar yolculuğunu başlatalım.';
    final ratio = review.effectiveReviewGoal <= 0
        ? 0.0
        : (review.reviewsCompletedToday / review.effectiveReviewGoal).clamp(
            0.0,
            1.0,
          );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accentEnd],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed ? Icons.task_alt_rounded : Icons.auto_awesome_rounded,
                color: AppColors.surface,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'BUGÜNÜN ODAĞI',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: AppColors.surface, fontSize: 28, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.surface.withValues(alpha: .9)),
          ),
          if (review.effectiveReviewGoal > 0 && questionCount == null) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Semantics(
                  label:
                      'Günlük hedef: ${review.reviewsCompletedToday} / ${review.effectiveReviewGoal} soru',
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: ratio),
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 450),
                            builder: (context, value, _) => SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 4,
                                color: AppColors.surface,
                                backgroundColor: AppColors.surface.withValues(
                                  alpha: .22,
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            completed
                                ? Icons.check_rounded
                                : Icons.trending_up_rounded,
                            color: AppColors.surface,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${review.reviewsCompletedToday} / ${review.effectiveReviewGoal} soru',
                        style: const TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        completed
                            ? 'Bugünkü hedef tamam'
                            : 'Her adım birikiyor',
                        style: TextStyle(
                          color: AppColors.surface.withValues(alpha: .85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (questionCount != null && review.effectiveReviewGoal > 0) ...[
            const SizedBox(height: 16),
            Text(
              'Bugünkü hedef: ${review.reviewsCompletedToday} / ${review.effectiveReviewGoal} soru',
              style: TextStyle(
                color: AppColors.surface.withValues(alpha: .9),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 4,
                color: AppColors.surface,
                backgroundColor: AppColors.surface.withValues(alpha: .2),
              ),
            ),
          ],
          if (questionCount != null) ...[
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _count(context, review.dueCount, 'bekleyen tekrar'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _count(context, questionCount!, 'defterdeki soru'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.surface.withValues(
                  alpha: .8,
                ),
                minimumSize: const Size(0, 52),
              ),
              onPressed: busy ? null : onPressed,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                busy ? 'Hazırlanıyor…' : label,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _count(BuildContext context, int value, String label) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: AppColors.surface),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.surface.withValues(alpha: .85)),
        ),
      ],
    ),
  );
}
