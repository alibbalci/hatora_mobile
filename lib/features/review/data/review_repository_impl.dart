import '../../../core/error/failure_mapper.dart';
import '../domain/review_models.dart';
import '../domain/review_repository.dart';
import 'review_mapper.dart';
import 'review_remote_data_source.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this.remote);
  final ReviewRemoteDataSource remote;

  @override
  Future<ReviewSetupData> getSetup() => repositoryCall(() async {
    final summary = await remote.dueSummary();
    final counts = await remote.dueCounts();
    return ReviewSetupData(
      totalDue: summary.totalDue,
      subjects: List.unmodifiable(counts.items.map(mapDueCount)),
    );
  });
  @override
  Future<List<DueCountItem>> getDueCounts({String? subjectId}) =>
      repositoryCall(
        () async => List.unmodifiable(
          (await remote.dueCounts(subjectId: subjectId)).items.map(mapDueCount),
        ),
      );
  @override
  Future<ReviewSession> createOrResume({String? subjectId, String? topicId}) =>
      repositoryCall(
        () async => mapSession(
          await remote.createOrResume(subjectId: subjectId, topicId: topicId),
        ),
      );
  @override
  Future<List<ReviewSession>> getSessions({ReviewSessionStatus? status}) =>
      repositoryCall(
        () async => List.unmodifiable(
          (await remote.sessions(
            status: status == null ? null : _statusWire[status]!,
          )).map(mapSession),
        ),
      );
  @override
  Future<ReviewSession> getSession(String id) =>
      repositoryCall(() async => mapSession(await remote.session(id)));
  @override
  Future<NextReviewItem?> getNextItem(String sessionId) =>
      repositoryCall(() async {
        final dto = await remote.nextItem(sessionId);
        return dto == null ? null : mapNextItem(dto);
      });
  @override
  Future<AnswerResult> submitAnswer(
    String itemId, {
    String? selectedAnswer,
    required bool unsolved,
  }) => repositoryCall(
    () async => mapAnswerResult(
      await remote.submitAnswer(
        itemId,
        selectedAnswer: selectedAnswer,
        unsolved: unsolved,
      ),
    ),
  );
  @override
  Future<ReviewImage> loadImage(Uri uri) =>
      repositoryCall(() => remote.image(uri));
}

const _statusWire = {
  ReviewSessionStatus.inProgress: 'IN_PROGRESS',
  ReviewSessionStatus.completed: 'COMPLETED',
  ReviewSessionStatus.abandoned: 'ABANDONED',
};
