import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../domain/get_statistics_use_case.dart';
import '../domain/statistics_models.dart';

enum StatisticsPhase { loading, ready, error }

class StatisticsState {
  const StatisticsState({
    this.phase = StatisticsPhase.loading,
    this.range = StatsRange.last7Days,
    this.bundle,
    this.failure,
    this.refreshing = false,
  });
  final StatisticsPhase phase;
  final StatsRange range;
  final StatisticsBundle? bundle;
  final AppFailure? failure;
  final bool refreshing;
}

class StatisticsViewModel extends Notifier<StatisticsState> {
  StatisticsViewModel(this.resolve);
  final GetStatisticsUseCase Function(Ref) resolve;

  @override
  StatisticsState build() {
    Future.microtask(load);
    return const StatisticsState();
  }

  Future<void> load() => _fetch(state.range);
  Future<void> refresh() => _fetch(state.range, refreshing: true);
  Future<void> retry() => _fetch(state.range);
  Future<void> changeRange(StatsRange range) => _fetch(range);

  Future<void> _fetch(StatsRange range, {bool refreshing = false}) async {
    state = StatisticsState(
      range: range,
      bundle: state.bundle,
      refreshing: refreshing && state.bundle != null,
    );
    try {
      final bundle = await resolve(ref)(range);
      if (ref.mounted) {
        state = StatisticsState(
          phase: StatisticsPhase.ready,
          range: range,
          bundle: bundle,
        );
      }
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = StatisticsState(
          phase: StatisticsPhase.error,
          range: range,
          bundle: state.bundle,
          failure: failure,
        );
      }
    }
  }
}
