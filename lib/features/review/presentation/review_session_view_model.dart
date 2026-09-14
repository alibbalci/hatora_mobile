import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../domain/review_models.dart';
import '../domain/review_use_cases.dart';
import 'review_states.dart';

class ReviewSessionViewModel extends Notifier<ReviewSessionState> {
  ReviewSessionViewModel(this.context, this.resolve);
  final ReviewSessionContext context;
  final ({GetNextReviewItemUseCase next, SubmitReviewAnswerUseCase submit})
  Function(Ref)
  resolve;
  @override
  ReviewSessionState build() {
    Future.microtask(loadNext);
    return const ReviewSessionState();
  }

  Future<void> loadNext() async {
    state = const ReviewSessionState();
    try {
      final item = await resolve(ref).next(context.sessionId);
      if (!ref.mounted) return;
      if (item == null) {
        final session = await resolve(ref).next.session(context.sessionId);
        if (!ref.mounted) return;
        state = ReviewSessionState(
          phase: session.status == ReviewSessionStatus.abandoned
              ? ReviewSessionPhase.inactive
              : ReviewSessionPhase.completed,
          session: session,
        );
        return;
      }
      final image = await resolve(ref).next.image(item.imageUri);
      if (ref.mounted) {
        state = ReviewSessionState(
          phase: ReviewSessionPhase.ready,
          item: item,
          image: image,
        );
      }
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = ReviewSessionState(
          phase: ReviewSessionPhase.error,
          failure: failure,
        );
      }
    }
  }

  void selectAnswer(String value) {
    if (state.phase == ReviewSessionPhase.ready) {
      state = ReviewSessionState(
        phase: state.phase,
        item: state.item,
        image: state.image,
        selectedAnswer: value,
      );
    }
  }

  void selectUnsolved() {
    if (state.phase == ReviewSessionPhase.ready) {
      state = ReviewSessionState(
        phase: state.phase,
        item: state.item,
        image: state.image,
        unsolved: true,
      );
    }
  }

  Future<void> submit() async {
    final previous = state;
    final item = previous.item;
    if (previous.phase != ReviewSessionPhase.ready ||
        !previous.canSubmit ||
        item == null) {
      return;
    }
    state = ReviewSessionState(
      phase: ReviewSessionPhase.submitting,
      item: item,
      image: previous.image,
      selectedAnswer: previous.selectedAnswer,
      unsolved: previous.unsolved,
    );
    try {
      final result = await resolve(ref).submit(
        item.itemId,
        selectedAnswer: previous.selectedAnswer,
        unsolved: previous.unsolved,
      );
      if (ref.mounted) {
        state = ReviewSessionState(
          phase: ReviewSessionPhase.result,
          item: item,
          image: previous.image,
          selectedAnswer: previous.selectedAnswer,
          unsolved: previous.unsolved,
          result: result,
        );
      }
    } on AppFailure catch (failure) {
      if (!ref.mounted) return;
      if (failure.code == 'SESSION_NOT_ACTIVE') {
        ReviewSession? session;
        try {
          session = await resolve(ref).next.session(context.sessionId);
        } on AppFailure {
          // The stable backend code is sufficient when detail refresh also fails.
        }
        if (ref.mounted) {
          state = ReviewSessionState(
            phase: ReviewSessionPhase.inactive,
            failure: failure,
            session: session,
          );
        }
      } else {
        state = ReviewSessionState(
          phase: ReviewSessionPhase.ready,
          item: item,
          image: previous.image,
          selectedAnswer: previous.selectedAnswer,
          unsolved: previous.unsolved,
          failure: failure,
        );
      }
    }
  }
}
