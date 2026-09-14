import '../domain/dashboard_models.dart';
import 'dashboard_dto.dart';

DashboardSummary mapDashboard(DashboardDto d) => DashboardSummary(
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
