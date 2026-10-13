import 'package:flutter/material.dart';

import '../../../core/design/app_stat_card.dart';
import '../../../core/widget/reference_widgets.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../question/presentation/question_screens.dart' show reasonLabels;
import '../domain/statistics_models.dart';

const statsRangeLabels = {
  StatsRange.last7Days: '7 gün',
  StatsRange.last30Days: '30 gün',
  StatsRange.allTime: 'Tümü',
};

class StatsRangeSelector extends StatelessWidget {
  const StatsRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final StatsRange selected;
  final ValueChanged<StatsRange> onChanged;
  @override
  Widget build(BuildContext context) => ReferenceSegments<StatsRange>(
    values: statsRangeLabels,
    selected: selected,
    onChanged: onChanged,
  );
}

String _pct(double value) => '%${value.toStringAsFixed(1)}';

class GeneralOverviewCard extends StatelessWidget {
  const GeneralOverviewCard({super.key, required this.stats});
  final GeneralStatistics stats;
  @override
  Widget build(BuildContext context) => AppStatGrid(
    children: [
      AppStatCard(
        icon: Icons.check_circle_outline,
        value: _pct(stats.successRate),
        label: 'Başarı oranı',
        color: AppColors.success,
      ),
      AppStatCard(
        icon: Icons.local_fire_department,
        value: '${stats.currentStreak} gün',
        label: 'Güncel seri',
        color: AppColors.error,
      ),
      AppStatCard(
        icon: Icons.replay_outlined,
        value: '${stats.totalReviews}',
        label: 'Toplam tekrar',
      ),
      AppStatCard(
        icon: Icons.auto_stories_outlined,
        value: '${stats.activeQuestionCount}',
        label: 'Aktif sorular',
      ),
      AppStatCard(
        icon: Icons.emoji_events_outlined,
        value: '${stats.masteredQuestionCount}',
        label: 'Ustalaşılan sorular',
        color: AppColors.success,
      ),
      AppStatCard(
        icon: Icons.military_tech_outlined,
        value: '${stats.longestStreak} gün',
        label: 'En uzun seri',
        color: AppColors.warning,
      ),
    ],
  );
}

class SubjectStatsCard extends StatelessWidget {
  const SubjectStatsCard({super.key, required this.stats});
  final SubjectStatistics stats;
  @override
  Widget build(BuildContext context) => _PerformanceRow(
    title: stats.subjectName,
    successRate: stats.successRate,
    trailing: '${stats.reviewCount} tekrar · Öğrenilen ${stats.masteredCount}',
  );
}

class TopicStatsCard extends StatelessWidget {
  const TopicStatsCard({super.key, required this.stats});
  final TopicStatistics stats;
  @override
  Widget build(BuildContext context) => _PerformanceRow(
    title: stats.topicName,
    subtitle: stats.subjectName,
    successRate: stats.successRate,
    trailing: '${stats.reviewCount} tekrar · Öğrenilen ${stats.masteredCount}',
  );
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({
    required this.title,
    this.subtitle,
    required this.successRate,
    required this.trailing,
  });
  final String title;
  final String? subtitle;
  final double successRate;
  final String trailing;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _pct(successRate),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (successRate / 100).clamp(0.0, 1.0),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(trailing, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    ),
  );
}

class MistakeReasonBar extends StatelessWidget {
  const MistakeReasonBar({super.key, required this.stats});
  final MistakeReasonStatistics stats;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                reasonLabels[stats.reason]!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              '${stats.count} · ${_pct(stats.percentage)}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (stats.percentage / 100).clamp(0.0, 1.0),
            minHeight: 6,
          ),
        ),
      ],
    ),
  );
}

class LearningInsightsCard extends StatelessWidget {
  const LearningInsightsCard({super.key, required this.insights});
  final LearningInsights insights;
  @override
  Widget build(BuildContext context) {
    if (!insights.hasRankings && insights.mostCommonMistakeReason == null) {
      return const _InsightEmptyCard();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insights.mostCommonMistakeReason != null)
          _InsightTile(
            icon: Icons.psychology_alt_outlined,
            title: 'En sık hata nedeni',
            value: reasonLabels[insights.mostCommonMistakeReason]!,
          ),
        if (!insights.hasRankings)
          const _InsightEmptyCard()
        else ...[
          _rankTile(
            context,
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            title: 'En güçlü ders',
            items: insights.strongestSubjects.map(
              (s) => '${s.subjectName} (${_pct(s.successRate)})',
            ),
          ),
          _rankTile(
            context,
            icon: Icons.trending_down_rounded,
            color: AppColors.warning,
            title: 'En zayıf ders',
            items: insights.weakestSubjects.map(
              (s) => '${s.subjectName} (${_pct(s.successRate)})',
            ),
          ),
          _rankTile(
            context,
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            title: 'En güçlü konu',
            items: insights.strongestTopics.map(
              (t) => '${t.topicName} (${_pct(t.successRate)})',
            ),
          ),
          _rankTile(
            context,
            icon: Icons.trending_down_rounded,
            color: AppColors.warning,
            title: 'En zayıf konu',
            items: insights.weakestTopics.map(
              (t) => '${t.topicName} (${_pct(t.successRate)})',
            ),
          ),
          _rankTile(
            context,
            icon: Icons.priority_high_rounded,
            color: AppColors.error,
            title: 'En zorlayıcı konu',
            items: insights.hardestTopics.map(
              (t) => '${t.topicName} (${_pct(t.successRate)})',
            ),
          ),
        ],
      ],
    );
  }

  Widget _rankTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required Iterable<String> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _InsightTile(
      icon: icon,
      iconColor: color,
      title: title,
      value: items.join(' · '),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor = AppColors.accent,
  });
  final IconData icon;
  final Color iconColor;
  final String title, value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _InsightEmptyCard extends StatelessWidget {
  const _InsightEmptyCard();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Text(
        'Henüz yeterli tekrar verisi yok.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}
