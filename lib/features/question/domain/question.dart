import 'dart:typed_data';

import '../../catalog/domain/catalog.dart';

enum ImageOrigin { camera, gallery }

class SelectedImage {
  SelectedImage({
    required Uint8List bytes,
    required this.name,
    required this.mimeType,
  }) : bytes = bytes.asUnmodifiableView();
  final Uint8List bytes;
  final String name, mimeType;
}

abstract interface class ImagePickerService {
  Future<SelectedImage?> pick(ImageOrigin origin);
  Future<SelectedImage?> recover();
}

enum AnalysisStatus { pending, completed, failed, confirmed, expired }

class QuestionAnalysis {
  const QuestionAnalysis({
    required this.id,
    required this.status,
    required this.manualSelectionRequired,
    required this.expiresAt,
    this.imageUri,
    this.suggestedSectionId,
    this.suggestedSubjectId,
    this.suggestedTopicId,
    this.confidence,
  });
  final String id;
  final AnalysisStatus status;
  final bool manualSelectionRequired;
  final DateTime expiresAt;
  final Uri? imageUri;
  final String? suggestedSectionId, suggestedSubjectId, suggestedTopicId;
  final double? confidence;
}

enum MistakeReason {
  carelessness,
  conceptGap,
  calculationError,
  misread,
  forgotInformation,
  timePressure,
  other,
}

enum Difficulty { hard, medium, easy }

enum QuestionStatus { active, mastered, archived, unknown }

class QuestionSummary {
  const QuestionSummary({
    required this.id,
    required this.topicId,
    required this.topicName,
    required this.subjectId,
    required this.subjectName,
    required this.examCode,
    required this.correctAnswer,
    required this.difficulty,
    required this.mistakeReason,
    required this.reviewStage,
    required this.status,
    required this.createdAt,
    this.imageUri,
    this.nextReviewDate,
  });
  final String id,
      topicId,
      topicName,
      subjectId,
      subjectName,
      examCode,
      correctAnswer;
  final Difficulty difficulty;
  final MistakeReason mistakeReason;
  final int reviewStage;
  final QuestionStatus status;
  final DateTime createdAt;
  final Uri? imageUri;
  final DateTime? nextReviewDate;
}

class QuestionPage {
  const QuestionPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });
  final List<QuestionSummary> items;
  final int page, size, totalElements, totalPages;
  final bool first, last;
}

class QuestionFilters {
  const QuestionFilters({
    this.status,
    this.subjectId,
    this.topicId,
    this.difficulty,
    this.mistakeReason,
  });
  final QuestionStatus? status;
  final String? subjectId, topicId;
  final Difficulty? difficulty;
  final MistakeReason? mistakeReason;
}

class QuestionUpdate {
  const QuestionUpdate({
    required this.topicId,
    required this.correctAnswer,
    required this.mistakeReason,
    required this.difficulty,
    required this.shortNote,
    required this.source,
  });
  final String topicId, correctAnswer, shortNote, source;
  final MistakeReason mistakeReason;
  final Difficulty difficulty;
}

class QuestionImage {
  const QuestionImage(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String? mimeType;
}

class SolutionImage {
  const SolutionImage({
    required this.id,
    required this.imageUri,
    required this.sortOrder,
  });
  final String id;
  final Uri imageUri;
  final int sortOrder;
}

class QuestionDraft {
  const QuestionDraft({
    required this.analysisId,
    required this.topicId,
    required this.correctAnswer,
    required this.mistakeReason,
    required this.difficulty,
    this.shortNote = '',
    this.source = '',
  });
  final String analysisId, topicId, correctAnswer, shortNote, source;
  final MistakeReason mistakeReason;
  final Difficulty difficulty;
}

class Question {
  const Question({
    required this.id,
    required this.topicName,
    required this.subjectName,
    required this.correctAnswer,
    required this.difficulty,
    required this.mistakeReason,
    this.topicId = '',
    this.subjectId = '',
    this.sectionName = '',
    this.examCode = '',
    this.shortNote = '',
    this.source = '',
    this.reviewStage = 0,
    this.status = QuestionStatus.active,
    this.solutionImages = const [],
    this.imageUri,
    this.nextReviewDate,
    this.createdAt,
    this.updatedAt,
    this.firstReviewedAt,
  });
  final String id,
      topicId,
      topicName,
      subjectId,
      subjectName,
      sectionName,
      examCode,
      correctAnswer,
      shortNote,
      source;
  final Difficulty difficulty;
  final MistakeReason mistakeReason;
  final Uri? imageUri;
  final DateTime? nextReviewDate;
  final int reviewStage;
  final QuestionStatus status;
  final List<SolutionImage> solutionImages;
  final DateTime? createdAt, updatedAt, firstReviewedAt;
}

abstract interface class QuestionRepository {
  Future<QuestionAnalysis> analyze(SelectedImage image);
  Future<Question> create(QuestionDraft draft);
  Future<QuestionPage> getQuestions({
    int page = 0,
    int size = 20,
    QuestionFilters filters = const QuestionFilters(),
  });
  Future<Question> getQuestion(String id);
  Future<Question> updateQuestion(String id, QuestionUpdate update);
  Future<void> archiveQuestion(String id);
  Future<QuestionImage> loadImage(Uri uri);
}

class ConfirmationSeed {
  const ConfirmationSeed(this.analysis, this.image);
  final QuestionAnalysis analysis;
  final SelectedImage image;
}

class ConfirmationContext {
  const ConfirmationContext(this.seed, this.catalog);
  final ConfirmationSeed seed;
  final QuestionCatalog catalog;
}
