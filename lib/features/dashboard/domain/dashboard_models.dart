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
    this.study,
  });
  final DashboardActiveExam activeExam;
  final DashboardReviewSummary review;
  final DashboardProgressSummary progress;
  final DashboardQuestionSummary questions;
  final DashboardStudySummary? study;
}

class DashboardStudyDay {
  const DashboardStudyDay({
    required this.date,
    required this.reviewsCompleted,
    required this.questionsAdded,
    required this.goalCompleted,
  });
  final DateTime date;
  final int reviewsCompleted, questionsAdded;
  final bool goalCompleted;
  bool get active => reviewsCompleted > 0 || questionsAdded > 0;
}

class DashboardStudySummary {
  const DashboardStudySummary({
    required this.today,
    required this.weekDays,
    required this.tomorrowQuestionCount,
    required this.tomorrowTopicCount,
    this.upcomingDays = const [],
  });
  final DateTime today;
  final List<DashboardStudyDay> weekDays;
  final int tomorrowQuestionCount, tomorrowTopicCount;
  final List<UpcomingStudyDay> upcomingDays;
}

class UpcomingStudyDay {
  const UpcomingStudyDay({
    required this.date,
    required this.questionCount,
    required this.subjects,
  });
  final DateTime date;
  final int questionCount;
  final List<String> subjects;
}
