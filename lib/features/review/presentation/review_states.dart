import '../../../core/error/app_failure.dart';
import '../domain/review_models.dart';

enum ReviewSetupPhase { loading, ready, empty, starting, error }

class ReviewSetupState {
  const ReviewSetupState({
    this.phase = ReviewSetupPhase.loading,
    this.data,
    this.topics = const [],
    this.selectedSubject,
    this.selectedTopic,
    this.failure,
    this.started,
  });
  final ReviewSetupPhase phase;
  final ReviewSetupData? data;
  final List<DueCountItem> topics;
  final DueCountItem? selectedSubject, selectedTopic;
  final AppFailure? failure;
  final ReviewSessionContext? started;
}

enum ReviewSessionPhase {
  loading,
  ready,
  submitting,
  result,
  completed,
  inactive,
  error,
}

class ReviewSessionState {
  const ReviewSessionState({
    this.phase = ReviewSessionPhase.loading,
    this.item,
    this.image,
    this.selectedAnswer,
    this.unsolved = false,
    this.result,
    this.failure,
    this.session,
  });
  final ReviewSessionPhase phase;
  final NextReviewItem? item;
  final ReviewImage? image;
  final String? selectedAnswer;
  final bool unsolved;
  final AnswerResult? result;
  final AppFailure? failure;
  final ReviewSession? session;
  bool get canSubmit => selectedAnswer != null || unsolved;
}
