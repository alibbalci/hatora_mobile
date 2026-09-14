class DashboardActiveExam {
  const DashboardActiveExam({
    required this.examId,
    required this.examEditionId,
    required this.examName,
    required this.examYear,
    this.examDate,
    this.daysUntilExam,
  });
  final String examId, examEditionId, examName;
  final int examYear;
  final DateTime? examDate;
  final int? daysUntilExam;
}

class DashboardReviewSummary {
  const DashboardReviewSummary({
    required this.dueCount,
    required this.reviewsCompletedToday,
    required this.effectiveReviewGoal,
    required this.goalCompleted,
    required this.hasActiveReviewSession,
    this.activeReviewSessionId,
  });
  final int dueCount, reviewsCompletedToday, effectiveReviewGoal;
  final bool goalCompleted, hasActiveReviewSession;
  final String? activeReviewSessionId;
}

class DashboardProgressSummary {
  const DashboardProgressSummary({
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
  });
  final int totalXp, level, currentStreak, longestStreak;
}

class DashboardQuestionSummary {
  const DashboardQuestionSummary({
    required this.activeCount,
    required this.masteredCount,
  });
  final int activeCount, masteredCount;
}

class DashboardSummary {
  const DashboardSummary({
    required this.activeExam,
    required this.review,
    required this.progress,
    required this.questions,
  });
  final DashboardActiveExam activeExam;
  final DashboardReviewSummary review;
  final DashboardProgressSummary progress;
  final DashboardQuestionSummary questions;
}
