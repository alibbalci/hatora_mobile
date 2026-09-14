import '../../question/data/question_mapper.dart';
import '../domain/review_models.dart';
import 'review_dto.dart';

T _wireEnum<T>(String value, Map<String, T> values) {
  final result = values[value];
  if (result == null) {
    throw FormatException('Unknown review enum value: $value');
  }
  return result;
}

const _sessionStatuses = {
  'IN_PROGRESS': ReviewSessionStatus.inProgress,
  'COMPLETED': ReviewSessionStatus.completed,
  'ABANDONED': ReviewSessionStatus.abandoned,
};
const _itemStatuses = {
  'PENDING': ReviewSessionItemStatus.pending,
  'ANSWERED': ReviewSessionItemStatus.answered,
  'SKIPPED': ReviewSessionItemStatus.skipped,
};
const _results = {
  'CORRECT': ReviewResult.correct,
  'WRONG': ReviewResult.wrong,
  'UNSOLVED': ReviewResult.unsolved,
};
const _skipReasons = {'QUESTION_ARCHIVED': SkipReason.questionArchived};

DueCountItem mapDueCount(DueCountItemDto dto) =>
    DueCountItem(id: dto.id, name: dto.name, count: dto.count);

ReviewSessionItem mapSessionItem(ReviewSessionItemDto dto) => ReviewSessionItem(
  id: dto.id,
  questionId: dto.questionId,
  position: dto.position,
  status: _wireEnum(dto.status, _itemStatuses),
  scheduledReviewDate: DateTime.parse(dto.scheduledReviewDate),
  skipReason: dto.skipReason == null
      ? null
      : _wireEnum(dto.skipReason!, _skipReasons),
  answeredAt: dto.answeredAt == null ? null : DateTime.parse(dto.answeredAt!),
);

ReviewSession mapSession(ReviewSessionDto dto) => ReviewSession(
  id: dto.id,
  subjectId: dto.subjectId,
  subjectName: dto.subjectName,
  topicId: dto.topicId,
  topicName: dto.topicName,
  startedDate: DateTime.parse(dto.startedDate),
  status: _wireEnum(dto.status, _sessionStatuses),
  startedAt: DateTime.parse(dto.startedAt),
  completedAt: dto.completedAt == null
      ? null
      : DateTime.parse(dto.completedAt!),
  abandonedAt: dto.abandonedAt == null
      ? null
      : DateTime.parse(dto.abandonedAt!),
  totalItems: dto.totalItems,
  pendingItems: dto.pendingItems,
  answeredItems: dto.answeredItems,
  skippedItems: dto.skippedItems,
  items: List.unmodifiable(dto.items.map(mapSessionItem)),
);

NextReviewItem mapNextItem(NextReviewItemDto dto) => NextReviewItem(
  itemId: dto.itemId,
  questionId: dto.questionId,
  position: dto.position,
  totalItems: dto.totalItems,
  topicId: dto.topicId,
  topicName: dto.topicName,
  subjectId: dto.subjectId,
  subjectName: dto.subjectName,
  examCode: dto.examCode,
  imageUri: Uri.parse(dto.imageAccessUri),
  difficulty: _wireEnum(
    dto.difficulty,
    difficultyWire.map((k, v) => MapEntry(v, k)),
  ),
);

AnswerResult mapAnswerResult(AnswerResultDto dto) => AnswerResult(
  itemId: dto.itemId,
  questionId: dto.questionId,
  skipped: dto.skipped,
  skipReason: dto.skipReason == null
      ? null
      : _wireEnum(dto.skipReason!, _skipReasons),
  result: dto.result == null ? null : _wireEnum(dto.result!, _results),
  selectedAnswer: dto.selectedAnswer,
  correctAnswer: dto.correctAnswer,
  previousStage: dto.previousStage,
  newStage: dto.newStage,
  nextReviewDate: DateTime.parse(dto.nextReviewDate),
  questionStatus: dto.questionStatus,
  mastered: dto.mastered,
  shortNote: dto.shortNote,
  mistakeReason: dto.mistakeReason == null
      ? null
      : _wireEnum(
          dto.mistakeReason!,
          mistakeReasonWire.map((k, v) => MapEntry(v, k)),
        ),
  solutionImages: List.unmodifiable(
    dto.solutionImages.map(
      (e) => SolutionImage(e.id, Uri.parse(e.imageAccessUri), e.sortOrder),
    ),
  ),
  imageUri: Uri.parse(dto.imageAccessUri),
  sessionCompleted: dto.sessionCompleted,
);
