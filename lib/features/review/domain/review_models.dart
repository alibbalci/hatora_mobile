import 'dart:typed_data';

import '../../question/domain/question.dart';

enum ReviewSessionStatus { inProgress, completed, abandoned }

enum ReviewSessionItemStatus { pending, answered, skipped }

enum ReviewResult { correct, wrong, unsolved }

enum SkipReason { questionArchived }

class DueCountItem {
  const DueCountItem({
    required this.id,
    required this.name,
    required this.count,
  });
  final String id, name;
  final int count;
}

class ReviewSetupData {
  const ReviewSetupData({required this.totalDue, required this.subjects});
  final int totalDue;
  final List<DueCountItem> subjects;
}

class ReviewSessionItem {
  const ReviewSessionItem({
    required this.id,
    required this.questionId,
    required this.position,
    required this.status,
    required this.scheduledReviewDate,
    this.skipReason,
    this.answeredAt,
  });
  final String id, questionId;
  final int position;
  final ReviewSessionItemStatus status;
  final DateTime scheduledReviewDate;
  final SkipReason? skipReason;
  final DateTime? answeredAt;
}

class ReviewSession {
  const ReviewSession({
    required this.id,
    required this.startedDate,
    required this.status,
    required this.startedAt,
    required this.totalItems,
    required this.pendingItems,
    required this.answeredItems,
    required this.skippedItems,
    required this.items,
    this.subjectId,
    this.subjectName,
    this.topicId,
    this.topicName,
    this.completedAt,
    this.abandonedAt,
  });
  final String id;
  final String? subjectId, subjectName, topicId, topicName;
  final DateTime startedDate, startedAt;
  final ReviewSessionStatus status;
  final DateTime? completedAt, abandonedAt;
  final int totalItems, pendingItems, answeredItems, skippedItems;
  final List<ReviewSessionItem> items;
}

class NextReviewItem {
  const NextReviewItem({
    required this.itemId,
    required this.questionId,
    required this.position,
    required this.totalItems,
    required this.topicId,
    required this.topicName,
    required this.subjectId,
    required this.subjectName,
    required this.examCode,
    required this.imageUri,
    required this.difficulty,
  });
  final String itemId,
      questionId,
      topicId,
      topicName,
      subjectId,
      subjectName,
      examCode;
  final int position, totalItems;
  final Uri imageUri;
  final Difficulty difficulty;
}

class SolutionImage {
  const SolutionImage(this.id, this.imageUri, this.sortOrder);
  final String id;
  final Uri imageUri;
  final int sortOrder;
}

class AnswerResult {
  const AnswerResult({
    required this.itemId,
    required this.questionId,
    required this.skipped,
    required this.correctAnswer,
    required this.previousStage,
    required this.newStage,
    required this.nextReviewDate,
    required this.questionStatus,
    required this.mastered,
    required this.solutionImages,
    required this.imageUri,
    required this.sessionCompleted,
    this.skipReason,
    this.result,
    this.selectedAnswer,
    this.shortNote,
    this.mistakeReason,
  });
  final String itemId, questionId, correctAnswer, questionStatus;
  final bool skipped, mastered, sessionCompleted;
  final SkipReason? skipReason;
  final ReviewResult? result;
  final String? selectedAnswer, shortNote;
  final int previousStage, newStage;
  final DateTime? nextReviewDate;
  final MistakeReason? mistakeReason;
  final List<SolutionImage> solutionImages;
  final Uri imageUri;
}

class ReviewSessionContext {
  const ReviewSessionContext(this.sessionId, this.answerOptionCount);
  final String sessionId;
  final int answerOptionCount;
}

class ReviewImage {
  const ReviewImage(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String? mimeType;
}
