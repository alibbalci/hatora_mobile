import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/widget/components.dart';
import 'statistics_view_model.dart';
import 'statistics_widgets.dart';
import '../../../core/widget/reference_widgets.dart';
import 'statistics_reference_widgets.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsViewModelProvider);
    final vm = ref.read(statisticsViewModelProvider.notifier);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: PageBody(
          children: [
            const ReferenceHeader(title: 'İstatistikler', caption: 'Gelişimin'),
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
              const SizedBox(height: 18),
              StatisticsHero(stats: state.bundle!.general),
              const SizedBox(height: 14),
              StatisticsMetrics(stats: state.bundle!.general),
              const SectionHeader('Performans'),
              StatisticsPerformance(bundle: state.bundle!),
              const SizedBox(height: 28),
              StatisticsMistakes(rows: state.bundle!.mistakeReasons),
              const SectionHeader('Öğrenme içgörüsü'),
              StatisticsInsight(insights: state.bundle!.insights),
            ],
          ],
        ),
      ),
    );
  }
}
