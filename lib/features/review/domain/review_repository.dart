import 'review_models.dart';

abstract interface class ReviewRepository {
  Future<ReviewSetupData> getSetup();
  Future<List<DueCountItem>> getDueCounts({String? subjectId});
  Future<ReviewSession> createOrResume({String? subjectId, String? topicId});
  Future<List<ReviewSession>> getSessions({ReviewSessionStatus? status});
  Future<ReviewSession> getSession(String id);
  Future<NextReviewItem?> getNextItem(String sessionId);
  Future<AnswerResult> submitAnswer(
    String itemId, {
    String? selectedAnswer,
    required bool unsolved,
  });
  Future<ReviewImage> loadImage(Uri uri);
}
