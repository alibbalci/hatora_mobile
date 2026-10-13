class ActiveExamSummaryDto {
  ActiveExamSummaryDto.fromJson(Map<String, dynamic> json)
    : examId = json['examId'] as String,
      examEditionId = json['examEditionId'] as String,
      examName = json['examName'] as String,
      examYear = json['examYear'] as int,
      examDate = json['examDate'] as String?,
      daysUntilExam = (json['daysUntilExam'] as num?)?.toInt();
  final String examId, examEditionId, examName;
  final int examYear;
  final String? examDate;
  final int? daysUntilExam;
}

class ReviewSummaryDto {
  ReviewSummaryDto.fromJson(Map<String, dynamic> json)
    : dueCount = json['dueCount'] as int,
      reviewsCompletedToday = json['reviewsCompletedToday'] as int,
      effectiveReviewGoal = json['effectiveReviewGoal'] as int,
      goalCompleted = json['goalCompleted'] as bool,
      activeReviewSessionId = json['activeReviewSessionId'] as String?,
      hasActiveReviewSession = json['hasActiveReviewSession'] as bool;
  final int dueCount, reviewsCompletedToday, effectiveReviewGoal;
  final bool goalCompleted, hasActiveReviewSession;
  final String? activeReviewSessionId;
}

class DashboardProgressSummaryDto {
  DashboardProgressSummaryDto.fromJson(Map<String, dynamic> json)
    : totalXp = (json['totalXp'] as num).toInt(),
      level = json['level'] as int,
      currentStreak = json['currentStreak'] as int,
      longestStreak = json['longestStreak'] as int;
  final int totalXp, level, currentStreak, longestStreak;
}

class DashboardQuestionSummaryDto {
  DashboardQuestionSummaryDto.fromJson(Map<String, dynamic> json)
    : activeCount = (json['activeCount'] as num).toInt(),
      masteredCount = (json['masteredCount'] as num).toInt();
  final int activeCount, masteredCount;
}

class DashboardDto {
  DashboardDto.fromJson(Map<String, dynamic> json)
    : study = json['study'] is Map
          ? DashboardStudyDto.fromJson(
              Map<String, dynamic>.from(json['study'] as Map),
            )
          : null,
      activeExam = ActiveExamSummaryDto.fromJson(
        json['activeExam'] as Map<String, dynamic>,
      ),
      review = ReviewSummaryDto.fromJson(
        json['review'] as Map<String, dynamic>,
      ),
      progress = DashboardProgressSummaryDto.fromJson(
        json['progress'] as Map<String, dynamic>,
      ),
      questions = DashboardQuestionSummaryDto.fromJson(
        json['questions'] as Map<String, dynamic>,
      );
  final ActiveExamSummaryDto activeExam;
  final ReviewSummaryDto review;
  final DashboardProgressSummaryDto progress;
  final DashboardQuestionSummaryDto questions;
  final DashboardStudyDto? study;
}

class DashboardStudyDto {
  DashboardStudyDto.fromJson(Map<String, dynamic> json)
    : upcoming = (json['upcomingDays'] as List? ?? const [])
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList(),
      today = DateTime.parse(json['today'] as String),
      days = (json['weekDays'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList(),
      tomorrowQuestions = (json['tomorrowQuestionCount'] as num).toInt(),
      tomorrowTopics = (json['tomorrowTopicCount'] as num).toInt();
  final DateTime today;
  final List<Map<String, dynamic>> days, upcoming;
  final int tomorrowQuestions, tomorrowTopics;
}
