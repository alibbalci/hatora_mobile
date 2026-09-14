import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../review/domain/review_models.dart';
import '../../review/domain/review_use_cases.dart';
import '../domain/dashboard_models.dart';
import '../domain/get_dashboard_use_case.dart';

enum DashboardPhase { loading, ready, error }

class DashboardState {
  const DashboardState({
    this.phase = DashboardPhase.loading,
    this.summary,
    this.failure,
    this.refreshing = false,
    this.continuing = false,
    this.continueFailure,
    this.continueSession,
  });
  final DashboardPhase phase;
  final DashboardSummary? summary;
  final AppFailure? failure;
  final bool refreshing;
  final bool continuing;
  final AppFailure? continueFailure;
  final ReviewSessionContext? continueSession;
}

class DashboardViewModel extends Notifier<DashboardState> {
  DashboardViewModel(this.resolve);
  final ({
    GetDashboardUseCase load,
    GetReviewAnswerOptionsUseCase answerOptions,
  })
  Function(Ref)
  resolve;

  @override
  DashboardState build() {
    Future.microtask(load);
    return const DashboardState();
  }

  Future<void> load() async {
    state = DashboardState(
      summary: state.summary,
      refreshing: state.summary != null,
    );
    try {
      final summary = await resolve(ref).load();
      if (ref.mounted) {
        state = DashboardState(phase: DashboardPhase.ready, summary: summary);
      }
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = DashboardState(
          phase: DashboardPhase.error,
          summary: state.summary,
          failure: failure,
        );
      }
    }
  }

  Future<void> refresh() => load();
  Future<void> retry() => load();

  Future<void> continueReview() async {
    final summary = state.summary;
    final sessionId = summary?.review.activeReviewSessionId;
    if (summary == null || sessionId == null || state.continuing) return;
    state = DashboardState(
      phase: state.phase,
      summary: summary,
      continuing: true,
    );
    try {
      final optionCount = await resolve(ref).answerOptions();
      if (ref.mounted) {
        state = DashboardState(
          phase: state.phase,
          summary: summary,
          continueSession: ReviewSessionContext(sessionId, optionCount),
        );
      }
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = DashboardState(
          phase: state.phase,
          summary: summary,
          continueFailure: failure,
        );
      }
    }
  }

  void consumeContinueSession() {
    state = DashboardState(
      phase: state.phase,
      summary: state.summary,
      failure: state.failure,
    );
  }
}
