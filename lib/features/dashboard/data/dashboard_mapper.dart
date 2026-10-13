import '../domain/dashboard_models.dart';
import 'dashboard_dto.dart';

DashboardSummary mapDashboard(DashboardDto d) => DashboardSummary(
  study: d.study == null
      ? null
      : DashboardStudySummary(
          today: d.study!.today,
          upcomingDays: d.study!.upcoming
              .map(
                (v) => UpcomingStudyDay(
                  date: DateTime.parse(v['date'] as String),
                  questionCount: (v['questionCount'] as num).toInt(),
                  subjects: (v['subjects'] as List).cast<String>(),
                ),
              )
              .toList(),
          weekDays: d.study!.days
              .map(
                (v) => DashboardStudyDay(
                  date: DateTime.parse(v['date'] as String),
                  reviewsCompleted: (v['reviewsCompleted'] as num).toInt(),
                  questionsAdded: (v['questionsAdded'] as num).toInt(),
                  goalCompleted: v['goalCompleted'] as bool,
                ),
              )
              .toList(),
          tomorrowQuestionCount: d.study!.tomorrowQuestions,
          tomorrowTopicCount: d.study!.tomorrowTopics,
        ),
  activeExam: DashboardActiveExam(
    examId: d.activeExam.examId,
    examEditionId: d.activeExam.examEditionId,
    examName: d.activeExam.examName,
    examYear: d.activeExam.examYear,
    examDate: d.activeExam.examDate == null
        ? null
        : DateTime.parse(d.activeExam.examDate!),
    daysUntilExam: d.activeExam.daysUntilExam,
  ),
  review: DashboardReviewSummary(
    dueCount: d.review.dueCount,
    reviewsCompletedToday: d.review.reviewsCompletedToday,
    effectiveReviewGoal: d.review.effectiveReviewGoal,
    goalCompleted: d.review.goalCompleted,
    hasActiveReviewSession: d.review.hasActiveReviewSession,
    activeReviewSessionId: d.review.activeReviewSessionId,
  ),
  progress: DashboardProgressSummary(
    totalXp: d.progress.totalXp,
    level: d.progress.level,
    currentStreak: d.progress.currentStreak,
    longestStreak: d.progress.longestStreak,
  ),
  questions: DashboardQuestionSummary(
    activeCount: d.questions.activeCount,
    masteredCount: d.questions.masteredCount,
  ),
);
