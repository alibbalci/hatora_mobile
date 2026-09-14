import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../domain/review_models.dart';
import '../domain/review_use_cases.dart';
import 'review_states.dart';

class ReviewSetupViewModel extends Notifier<ReviewSetupState> {
  ReviewSetupViewModel(this.resolve);
  final ({
    LoadReviewSetupUseCase load,
    StartOrResumeReviewSessionUseCase start,
    GetReviewAnswerOptionsUseCase options,
  })
  Function(Ref)
  resolve;
  @override
  ReviewSetupState build() {
    Future.microtask(load);
    return const ReviewSetupState();
  }

  Future<void> load() async {
    state = const ReviewSetupState();
    try {
      final data = await resolve(ref).load();
      if (ref.mounted) {
        state = ReviewSetupState(
          phase: data.totalDue == 0
              ? ReviewSetupPhase.empty
              : ReviewSetupPhase.ready,
          data: data,
        );
      }
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = ReviewSetupState(
          phase: ReviewSetupPhase.error,
          failure: failure,
        );
      }
    }
  }

  Future<void> selectSubject(DueCountItem? subject) async {
    if (state.phase == ReviewSetupPhase.starting) return;
    final data = state.data;
    state = ReviewSetupState(
      phase: ReviewSetupPhase.ready,
      data: data,
      selectedSubject: subject,
    );
    if (subject == null) {
      return;
    }
    try {
      final topics = await resolve(ref).load.topics(subject.id);
      if (ref.mounted && state.selectedSubject?.id == subject.id) {
        state = ReviewSetupState(
          phase: ReviewSetupPhase.ready,
          data: data,
          selectedSubject: subject,
          topics: topics,
        );
      }
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = ReviewSetupState(
          phase: ReviewSetupPhase.error,
          data: data,
          selectedSubject: subject,
          failure: failure,
        );
      }
    }
  }

  void selectTopic(DueCountItem? topic) {
    if (state.phase != ReviewSetupPhase.ready) return;
    state = ReviewSetupState(
      phase: state.phase,
      data: state.data,
      topics: state.topics,
      selectedSubject: state.selectedSubject,
      selectedTopic: topic,
    );
  }

  Future<void> start() async {
    if (state.phase != ReviewSetupPhase.ready) return;
    final previous = state;
    state = ReviewSetupState(
      phase: ReviewSetupPhase.starting,
      data: previous.data,
      topics: previous.topics,
      selectedSubject: previous.selectedSubject,
      selectedTopic: previous.selectedTopic,
    );
    try {
      final session = await resolve(ref).start(
        subjectId: previous.selectedSubject?.id,
        topicId: previous.selectedTopic?.id,
      );
      final optionCount = await resolve(ref).options();
      if (ref.mounted) {
        state = ReviewSetupState(
          phase: ReviewSetupPhase.ready,
          data: previous.data,
          topics: previous.topics,
          selectedSubject: previous.selectedSubject,
          selectedTopic: previous.selectedTopic,
          started: ReviewSessionContext(session.id, optionCount),
        );
      }
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = ReviewSetupState(
          phase: ReviewSetupPhase.error,
          data: previous.data,
          topics: previous.topics,
          selectedSubject: previous.selectedSubject,
          selectedTopic: previous.selectedTopic,
          failure: failure,
        );
      }
    }
  }
}
