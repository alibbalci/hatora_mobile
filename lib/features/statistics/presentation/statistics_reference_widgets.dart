import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/reference_widgets.dart';
import '../../question/presentation/question_screens.dart' show reasonLabels;
import '../domain/statistics_models.dart';

class StatisticsHero extends StatelessWidget {
  const StatisticsHero({super.key, required this.stats});
  final GeneralStatistics stats;
  @override
  Widget build(BuildContext context) {
    final ring = SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: (stats.successRate / 100).clamp(0, 1),
              strokeWidth: 10,
              color: AppColors.accentEnd,
              backgroundColor: AppColors.surface.withValues(alpha: .18),
            ),
          ),
          SizedBox(
            width: 78,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '%${stats.successRate.toStringAsFixed(stats.successRate % 1 == 0 ? 0 : 1)}',
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'başarı',
                    style: TextStyle(
                      color: AppColors.surface.withValues(alpha: .65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stats.totalReviews == 0
              ? 'Henüz tekrar yok'
              : 'Her tekrar bir kazanım',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: AppColors.surface),
        ),
        const SizedBox(height: 6),
        Text(
          stats.totalReviews == 0
              ? 'İlk tekrarını yaptığında başarı oranın burada belirecek.'
              : '${stats.totalReviews} tekrarda ${stats.correctCount} doğru cevap verdin.',
          style: TextStyle(
            color: AppColors.surface.withValues(alpha: .72),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ReferenceTag(
              label: '${stats.currentStreak} gün seri',
              icon: Icons.local_fire_department_outlined,
              color: AppColors.surface,
              backgroundColor: AppColors.surface.withValues(alpha: .18),
            ),
            ReferenceTag(
              label: 'Rekor ${stats.longestStreak}',
              icon: Icons.emoji_events_outlined,
              color: AppColors.surface,
              backgroundColor: AppColors.surface.withValues(alpha: .18),
            ),
          ],
        ),
      ],
    );
    return ReferenceCard(
      color: AppColors.accent,
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 260 ||
              MediaQuery.textScalerOf(context).scale(14) > 18) {
            return Column(
              children: [ring, const SizedBox(height: 18), content],
            );
          }
          return Row(
            children: [
              ring,
              const SizedBox(width: 20),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class StatisticsMetrics extends StatelessWidget {
  const StatisticsMetrics({super.key, required this.stats});
  final GeneralStatistics stats;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final narrow = MediaQuery.textScalerOf(context).scale(14) > 18;
      final width = narrow ? c.maxWidth : (c.maxWidth - 12) / 2;
      final entries = [
        (
          Icons.auto_stories_outlined,
          '${stats.activeQuestionCount}',
          'Aktif soru',
          AppColors.accent,
        ),
        (
          Icons.replay_outlined,
          '${stats.totalReviews}',
          'Toplam tekrar',
          AppColors.accentEnd,
        ),
        (
          Icons.verified_outlined,
          '${stats.masteredQuestionCount}',
          'Ustalaşılan',
          AppColors.success,
        ),
        (
          Icons.local_fire_department_outlined,
          '${stats.longestStreak} gün',
          'En uzun seri',
          AppColors.warning,
        ),
      ];
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: entries
            .map(
              (e) => SizedBox(
                width: width,
                child: ReferenceCard(
                  padding: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: e.$4.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(e.$1, color: e.$4, size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.$2,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(
                              height: MediaQuery.textScalerOf(context)
                                  .scale(32),
                              child: Text(
                                e.$3,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class StatisticsPerformance extends StatefulWidget {
  const StatisticsPerformance({super.key, required this.bundle});
  final StatisticsBundle bundle;
  @override
  State<StatisticsPerformance> createState() => _StatisticsPerformanceState();
}

class _StatisticsPerformanceState extends State<StatisticsPerformance> {
  bool topic = false;
  @override
  Widget build(BuildContext context) {
    final rows = topic
        ? widget.bundle.topics
              .where((s) => s.reviewCount > 0)
              .map((s) => (s.topicName, s.successRate))
              .toList()
        : widget.bundle.subjects
              .where((s) => s.reviewCount > 0)
              .map((s) => (s.subjectName, s.successRate))
              .toList();
    return ReferenceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: ReferenceSegments(
              values: const {false: 'Ders', true: 'Konu'},
              selected: topic,
              onChanged: (v) => setState(() => topic = v),
            ),
          ),
          const SizedBox(height: 26),
          if (rows.isEmpty) ...[
            ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [36.0, 64.0, 50.0, 80.0, 28.0]
                    .map(
                      (h) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            height: h,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Bu aralıkta tekrar verisi yok',
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Tekrar yaptıkça ${topic ? 'konular' : 'dersler'} burada sıralanır.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else
            for (final row in rows) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '%${row.$2.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (row.$2 / 100).clamp(0, 1),
                  minHeight: 7,
                ),
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

class StatisticsMistakes extends StatelessWidget {
  const StatisticsMistakes({super.key, required this.rows});
  final List<MistakeReasonStatistics> rows;
  @override
  Widget build(BuildContext context) {
    final values = rows.where((s) => s.count > 0).toList();
    final total = values.fold<int>(0, (n, s) => n + s.count);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hata nedenleri',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text('$total hata', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        ReferenceCard(
          child: Column(
            children: [
              if (total > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: List.generate(
                      values.length,
                      (i) => Expanded(
                        flex: values[i].count,
                        child: Container(
                          height: 14,
                          margin: EdgeInsets.only(
                            right: i == values.length - 1 ? 0 : 3,
                          ),
                          color: [
                            AppColors.accent,
                            AppColors.mistakeOrange,
                            AppColors.success,
                            AppColors.error,
                            AppColors.accentEnd,
                          ][i % 5],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < values.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: [
                              AppColors.accent,
                              AppColors.mistakeOrange,
                              AppColors.success,
                              AppColors.error,
                              AppColors.accentEnd,
                            ][i % 5],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reasonLabels[values[i].reason]!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${values[i].count}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '%${values[i].percentage.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
              ] else
                Text(
                  'Henüz hata kaydı yok.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatisticsInsight extends StatelessWidget {
  const StatisticsInsight({super.key, required this.insights});
  final LearningInsights insights;
  @override
  Widget build(BuildContext context) {
    final reason = insights.mostCommonMistakeReason;
    return ReferenceCard(
      color: AppColors.accentSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.psychology_alt_outlined,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason == null
                      ? 'Birlikte keşfedelim'
                      : 'En sık hata nedenin',
                  style: const TextStyle(color: AppColors.accent, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  reason == null
                      ? 'Henüz yeterli tekrar verisi yok.'
                      : reasonLabels[reason]!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  reason == null
                      ? 'Tekrarlarını tamamladıkça gelişimin burada görünür.'
                      : 'Bu soruların konu anlatımına dönüp kısa bir özet çıkarmak işe yarayabilir.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.primaryInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
