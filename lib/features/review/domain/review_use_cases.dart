import '../../catalog/domain/catalog.dart';
import '../../onboarding/domain/onboarding.dart';
import '../../../core/error/app_failure.dart';
import 'review_models.dart';
import 'review_repository.dart';

class LoadReviewSetupUseCase {
  const LoadReviewSetupUseCase(this.repository);
  final ReviewRepository repository;
  Future<ReviewSetupData> call() => repository.getSetup();
  Future<List<DueCountItem>> topics(String subjectId) =>
      repository.getDueCounts(subjectId: subjectId);
}

class StartOrResumeReviewSessionUseCase {
  const StartOrResumeReviewSessionUseCase(this.repository);
  final ReviewRepository repository;
  Future<ReviewSession> call({String? subjectId, String? topicId}) =>
      repository.createOrResume(subjectId: subjectId, topicId: topicId);
}

class GetNextReviewItemUseCase {
  const GetNextReviewItemUseCase(this.repository);
  final ReviewRepository repository;
  Future<NextReviewItem?> call(String sessionId) =>
      repository.getNextItem(sessionId);
  Future<ReviewSession> session(String sessionId) =>
      repository.getSession(sessionId);
  Future<ReviewImage> image(Uri uri) => repository.loadImage(uri);
}

class SubmitReviewAnswerUseCase {
  const SubmitReviewAnswerUseCase(this.repository);
  final ReviewRepository repository;
  Future<AnswerResult> call(
    String itemId, {
    String? selectedAnswer,
    required bool unsolved,
  }) => repository.submitAnswer(
    itemId,
    selectedAnswer: selectedAnswer,
    unsolved: unsolved,
  );
}

class GetReviewAnswerOptionsUseCase {
  const GetReviewAnswerOptionsUseCase(this.onboarding, this.catalog);
  final OnboardingRepository onboarding;
  final CatalogRepository catalog;
  Future<int> call() async {
    final status = await onboarding.status();
    final examId = status.examId;
    if (examId == null) {
      throw const AppFailure(FailureKind.businessRule, code: 'NO_ACTIVE_EXAM');
    }
    return (await catalog.questionCatalog(examId)).exam.answerOptionCount;
  }
}
