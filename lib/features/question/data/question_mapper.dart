import '../domain/question.dart';
import 'question_dto.dart';

const mistakeReasonWire = {
  MistakeReason.carelessness: 'CARELESSNESS',
  MistakeReason.conceptGap: 'CONCEPT_GAP',
  MistakeReason.calculationError: 'CALCULATION_ERROR',
  MistakeReason.misread: 'MISREAD',
  MistakeReason.forgotInformation: 'FORGOT_INFORMATION',
  MistakeReason.timePressure: 'TIME_PRESSURE',
  MistakeReason.other: 'OTHER',
};
const difficultyWire = {
  Difficulty.hard: 'HARD',
  Difficulty.medium: 'MEDIUM',
  Difficulty.easy: 'EASY',
};

QuestionAnalysis mapAnalysis(QuestionAnalysisDto dto) => QuestionAnalysis(
  id: dto.id,
  status: AnalysisStatus.values.byName(dto.status.toLowerCase()),
  manualSelectionRequired: dto.manualSelectionRequired,
  expiresAt: DateTime.parse(dto.expiresAt),
  imageUri: dto.imageAccessUri == null ? null : Uri.parse(dto.imageAccessUri!),
  suggestedSectionId: dto.suggestedSectionId,
  suggestedSubjectId: dto.suggestedSubjectId,
  suggestedTopicId: dto.suggestedTopicId,
  confidence: dto.confidence,
);

Question mapQuestion(QuestionDto dto) => Question(
  id: dto.id,
  topicName: dto.topicName,
  subjectName: dto.subjectName,
  correctAnswer: dto.correctAnswer,
  difficulty: difficultyWire.entries
      .singleWhere((e) => e.value == dto.difficulty)
      .key,
  mistakeReason: mistakeReasonWire.entries
      .singleWhere((e) => e.value == dto.mistakeReason)
      .key,
  imageUri: dto.imageAccessUri == null ? null : Uri.parse(dto.imageAccessUri!),
  nextReviewDate: dto.nextReviewDate == null
      ? null
      : DateTime.parse(dto.nextReviewDate!),
  topicId: dto.topicId,
  subjectId: dto.subjectId,
  sectionName: dto.sectionName,
  examCode: dto.examCode,
  shortNote: dto.shortNote,
  source: dto.source,
  reviewStage: dto.reviewStage,
  status: _status(dto.questionStatus),
  createdAt: _dateTime(dto.createdAt),
  updatedAt: _dateTime(dto.updatedAt),
  firstReviewedAt: _dateTime(dto.firstReviewedAt),
  solutionImages: dto.solutionImages
      .map(
        (e) => SolutionImage(
          id: e.id,
          imageUri: Uri.parse(e.imageAccessUri),
          sortOrder: e.sortOrder,
        ),
      )
      .toList(),
);

QuestionSummary mapQuestionSummary(QuestionSummaryDto dto) => QuestionSummary(
  id: dto.id,
  topicId: dto.topicId,
  topicName: dto.topicName,
  subjectId: dto.subjectId,
  subjectName: dto.subjectName,
  examCode: dto.examCode,
  correctAnswer: dto.correctAnswer,
  difficulty: _difficulty(dto.difficulty),
  mistakeReason: _reason(dto.mistakeReason),
  reviewStage: dto.reviewStage,
  status: _status(dto.status),
  createdAt: DateTime.parse(dto.createdAt),
  imageUri: dto.imageAccessUri == null ? null : Uri.parse(dto.imageAccessUri!),
  nextReviewDate: dto.nextReviewDate == null
      ? null
      : DateTime.parse(dto.nextReviewDate!),
);

QuestionPage mapQuestionPage(QuestionPageDto dto) => QuestionPage(
  items: dto.content.map(mapQuestionSummary).toList(),
  page: dto.page,
  size: dto.size,
  totalElements: dto.totalElements,
  totalPages: dto.totalPages,
  first: dto.first,
  last: dto.last,
);

Difficulty _difficulty(String value) =>
    difficultyWire.entries.where((e) => e.value == value).firstOrNull?.key ??
    Difficulty.medium;
MistakeReason _reason(String value) =>
    mistakeReasonWire.entries.where((e) => e.value == value).firstOrNull?.key ??
    MistakeReason.other;
QuestionStatus _status(String value) => switch (value) {
  'ACTIVE' => QuestionStatus.active,
  'MASTERED' => QuestionStatus.mastered,
  'ARCHIVED' => QuestionStatus.archived,
  _ => QuestionStatus.unknown,
};
DateTime? _dateTime(String? value) =>
    value == null ? null : DateTime.parse(value);

Map<String, dynamic> mapQuestionUpdate(QuestionUpdate update) => {
  'topicId': update.topicId,
  'correctAnswer': update.correctAnswer,
  'mistakeReason': mistakeReasonWire[update.mistakeReason],
  'difficulty': difficultyWire[update.difficulty],
  'shortNote': update.shortNote,
  'source': update.source,
};

Map<String, dynamic> mapQuestionRequest(QuestionDraft draft) => {
  'analysisId': draft.analysisId,
  'topicId': draft.topicId,
  'correctAnswer': draft.correctAnswer,
  'mistakeReason': mistakeReasonWire[draft.mistakeReason],
  'difficulty': difficultyWire[draft.difficulty],
  'shortNote': draft.shortNote,
  'source': draft.source,
};
