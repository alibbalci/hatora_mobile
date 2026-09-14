import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/widget/components.dart';
import 'statistics_view_model.dart';
import 'statistics_widgets.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsViewModelProvider);
    final vm = ref.read(statisticsViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: PageBody(
          children: [
            StatsRangeSelector(
              selected: state.range,
              onChanged: vm.changeRange,
            ),
            const SizedBox(height: 8),
            if (state.phase == StatisticsPhase.loading && state.bundle == null)
              const LoadingView(label: 'İstatistikler yükleniyor…')
            else if (state.bundle == null)
              ErrorView(error: state.failure!, onRetry: vm.retry)
            else ...[
              if (state.failure != null)
                ErrorView(error: state.failure!, onRetry: vm.retry),
              const SectionHeader('Genel Bakış'),
              GeneralOverviewCard(stats: state.bundle!.general),
              const SectionHeader('Ders Performansı'),
              if (state.bundle!.subjects.isEmpty)
                const EmptyView(
                  title: 'Ders istatistiği yok',
                  message: 'Bu aralıkta henüz tekrar verisi bulunmuyor.',
                  icon: Icons.bar_chart,
                )
              else
                for (final s in state.bundle!.subjects)
                  SubjectStatsCard(stats: s),
              const SectionHeader('Konu Performansı'),
              if (state.bundle!.topics.isEmpty)
                const EmptyView(
                  title: 'Konu istatistiği yok',
                  message: 'Bu aralıkta henüz tekrar verisi bulunmuyor.',
                  icon: Icons.bar_chart,
                )
              else
                for (final t in state.bundle!.topics) TopicStatsCard(stats: t),
              const SectionHeader('Hata Nedenleri'),
              for (final m in state.bundle!.mistakeReasons)
                MistakeReasonBar(stats: m),
              const SectionHeader('Öğrenme İçgörüleri'),
              LearningInsightsCard(insights: state.bundle!.insights),
            ],
          ],
        ),
      ),
    );
  }
}
