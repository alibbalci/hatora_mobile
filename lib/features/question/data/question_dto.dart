class QuestionAnalysisDto {
  QuestionAnalysisDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      status = json['status'] as String,
      imageAccessUri = json['imageAccessUri'] as String?,
      suggestedSectionId = json['suggestedSectionId'] as String?,
      suggestedSubjectId = json['suggestedSubjectId'] as String?,
      suggestedTopicId = json['suggestedTopicId'] as String?,
      confidence = (json['confidence'] as num?)?.toDouble(),
      manualSelectionRequired = json['manualSelectionRequired'] as bool,
      expiresAt = json['expiresAt'] as String;
  final String id, status, expiresAt;
  final String? imageAccessUri,
      suggestedSectionId,
      suggestedSubjectId,
      suggestedTopicId;
  final double? confidence;
  final bool manualSelectionRequired;
}

class QuestionDto {
  QuestionDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      topicName = json['topicName'] as String,
      subjectName = json['subjectName'] as String,
      correctAnswer = json['correctAnswer'] as String,
      difficulty = json['difficulty'] as String,
      mistakeReason = json['mistakeReason'] as String,
      imageAccessUri = json['imageAccessUri'] as String?,
      nextReviewDate = json['nextReviewDate'] as String?,
      topicId = json['topicId'] as String? ?? '',
      subjectId = json['subjectId'] as String? ?? '',
      sectionName = json['sectionName'] as String? ?? '',
      examCode = json['examCode'] as String? ?? '',
      shortNote = json['shortNote'] as String? ?? '',
      source = json['source'] as String? ?? '',
      reviewStage = json['reviewStage'] as int? ?? 0,
      questionStatus = json['status'] as String? ?? 'ACTIVE',
      createdAt = json['createdAt'] as String?,
      updatedAt = json['updatedAt'] as String?,
      firstReviewedAt = json['firstReviewedAt'] as String?,
      solutionImages = (json['solutionImages'] as List<dynamic>? ?? const [])
          .map((e) => SolutionImageDto.fromJson(e as Map<String, dynamic>))
          .toList();
  final String id,
      topicName,
      subjectName,
      correctAnswer,
      difficulty,
      mistakeReason;
  final String? imageAccessUri, nextReviewDate;
  final String topicId,
      subjectId,
      sectionName,
      examCode,
      shortNote,
      source,
      questionStatus;
  final int reviewStage;
  final String? createdAt, updatedAt, firstReviewedAt;
  final List<SolutionImageDto> solutionImages;
}

class QuestionSummaryDto {
  QuestionSummaryDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      topicId = json['topicId'] as String,
      topicName = json['topicName'] as String,
      subjectId = json['subjectId'] as String,
      subjectName = json['subjectName'] as String,
      examCode = json['examCode'] as String,
      imageAccessUri = json['imageAccessUri'] as String?,
      correctAnswer = json['correctAnswer'] as String,
      difficulty = json['difficulty'] as String,
      mistakeReason = json['mistakeReason'] as String,
      reviewStage = json['reviewStage'] as int,
      nextReviewDate = json['nextReviewDate'] as String?,
      status = json['status'] as String,
      createdAt = json['createdAt'] as String;
  final String id,
      topicId,
      topicName,
      subjectId,
      subjectName,
      examCode,
      correctAnswer,
      difficulty,
      mistakeReason,
      status,
      createdAt;
  final String? imageAccessUri, nextReviewDate;
  final int reviewStage;
}

class QuestionPageDto {
  QuestionPageDto.fromJson(Map<String, dynamic> json)
    : content = (json['content'] as List<dynamic>)
          .map((e) => QuestionSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      page = json['page'] as int,
      size = json['size'] as int,
      totalElements = json['totalElements'] as int,
      totalPages = json['totalPages'] as int,
      first = json['first'] as bool,
      last = json['last'] as bool;
  final List<QuestionSummaryDto> content;
  final int page, size, totalElements, totalPages;
  final bool first, last;
}

class SolutionImageDto {
  SolutionImageDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      imageAccessUri = json['imageAccessUri'] as String,
      sortOrder = json['sortOrder'] as int;
  final String id, imageAccessUri;
  final int sortOrder;
}
