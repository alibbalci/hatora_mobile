class DueSummaryDto {
  DueSummaryDto.fromJson(Map<String, dynamic> json)
    : totalDue = json['totalDue'] as int;
  final int totalDue;
}

class DueCountItemDto {
  DueCountItemDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      count = (json['count'] as num).toInt();
  final String id, name;
  final int count;
}

class DueCountsDto {
  DueCountsDto.fromJson(Map<String, dynamic> json)
    : items = (json['items'] as List<dynamic>)
          .map((e) => DueCountItemDto.fromJson(e as Map<String, dynamic>))
          .toList();
  final List<DueCountItemDto> items;
}

class ReviewSessionItemDto {
  ReviewSessionItemDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      questionId = json['questionId'] as String,
      position = json['position'] as int,
      status = json['status'] as String,
      scheduledReviewDate = json['scheduledReviewDate'] as String,
      skipReason = json['skipReason'] as String?,
      answeredAt = json['answeredAt'] as String?;
  final String id, questionId, status, scheduledReviewDate;
  final int position;
  final String? skipReason, answeredAt;
}

class ReviewSessionDto {
  ReviewSessionDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      subjectId = json['subjectId'] as String?,
      subjectName = json['subjectName'] as String?,
      topicId = json['topicId'] as String?,
      topicName = json['topicName'] as String?,
      startedDate = json['startedDate'] as String,
      status = json['status'] as String,
      startedAt = json['startedAt'] as String,
      completedAt = json['completedAt'] as String?,
      abandonedAt = json['abandonedAt'] as String?,
      totalItems = json['totalItems'] as int,
      pendingItems = (json['pendingItems'] as num).toInt(),
      answeredItems = (json['answeredItems'] as num).toInt(),
      skippedItems = (json['skippedItems'] as num).toInt(),
      items = (json['items'] as List<dynamic>)
          .map((e) => ReviewSessionItemDto.fromJson(e as Map<String, dynamic>))
          .toList();
  final String id, startedDate, status, startedAt;
  final String? subjectId,
      subjectName,
      topicId,
      topicName,
      completedAt,
      abandonedAt;
  final int totalItems, pendingItems, answeredItems, skippedItems;
  final List<ReviewSessionItemDto> items;
}

class NextReviewItemDto {
  NextReviewItemDto.fromJson(Map<String, dynamic> json)
    : itemId = json['itemId'] as String,
      questionId = json['questionId'] as String,
      position = json['position'] as int,
      totalItems = json['totalItems'] as int,
      topicId = json['topicId'] as String,
      topicName = json['topicName'] as String,
      subjectId = json['subjectId'] as String,
      subjectName = json['subjectName'] as String,
      examCode = json['examCode'] as String,
      imageAccessUri = json['imageAccessUri'] as String,
      difficulty = json['difficulty'] as String;
  final String itemId, questionId, topicId, topicName, subjectId, subjectName;
  final String examCode, imageAccessUri, difficulty;
  final int position, totalItems;
}

class SolutionImageDto {
  SolutionImageDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      imageAccessUri = json['imageAccessUri'] as String,
      sortOrder = json['sortOrder'] as int;
  final String id, imageAccessUri;
  final int sortOrder;
}

class AnswerResultDto {
  AnswerResultDto.fromJson(Map<String, dynamic> json)
    : itemId = json['itemId'] as String,
      questionId = json['questionId'] as String,
      skipped = json['skipped'] as bool,
      skipReason = json['skipReason'] as String?,
      result = json['result'] as String?,
      selectedAnswer = json['selectedAnswer'] as String?,
      correctAnswer = json['correctAnswer'] as String,
      previousStage = json['previousStage'] as int,
      newStage = json['newStage'] as int,
      nextReviewDate = json['nextReviewDate'] as String,
      questionStatus = json['questionStatus'] as String,
      mastered = json['mastered'] as bool,
      shortNote = json['shortNote'] as String?,
      mistakeReason = json['mistakeReason'] as String?,
      solutionImages = (json['solutionImages'] as List<dynamic>)
          .map((e) => SolutionImageDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageAccessUri = json['imageAccessUri'] as String,
      sessionCompleted = json['sessionCompleted'] as bool;
  final String itemId,
      questionId,
      correctAnswer,
      nextReviewDate,
      questionStatus;
  final bool skipped, mastered, sessionCompleted;
  final String? skipReason, result, selectedAnswer, shortNote, mistakeReason;
  final int previousStage, newStage;
  final List<SolutionImageDto> solutionImages;
  final String imageAccessUri;
}
