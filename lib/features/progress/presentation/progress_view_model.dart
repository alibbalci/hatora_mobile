import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../domain/get_progress_use_case.dart';
import '../domain/progress_models.dart';

enum ProgressPhase { loading, ready, error }

class ProgressState {
  const ProgressState({
    this.phase = ProgressPhase.loading,
    this.progress,
    this.failure,
    this.refreshing = false,
  });
  final ProgressPhase phase;
  final UserProgress? progress;
  final AppFailure? failure;
  final bool refreshing;
}

class ProgressViewModel extends Notifier<ProgressState> {
  ProgressViewModel(this.resolve);
  final GetProgressUseCase Function(Ref) resolve;
  @override
  ProgressState build() {
    Future.microtask(load);
    return const ProgressState();
  }

  Future<void> load() async {
    state = ProgressState(
      progress: state.progress,
      refreshing: state.progress != null,
    );
    try {
      final p = await resolve(ref)();
      if (ref.mounted) {
        state = ProgressState(phase: ProgressPhase.ready, progress: p);
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = ProgressState(
          phase: ProgressPhase.error,
          progress: state.progress,
          failure: e,
        );
      }
    }
  }

  Future<void> refresh() => load();
  Future<void> retry() => load();
}
