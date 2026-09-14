import '../domain/progress_models.dart';
import 'progress_dto.dart';

DailyProgress mapDailyProgress(DailyProgressDto d) => DailyProgress(
  activityDate: DateTime.parse(d.activityDate),
  reviewGoal: d.reviewGoal,
  effectiveReviewGoal: d.effectiveReviewGoal,
  reviewsCompleted: d.reviewsCompleted,
  correctCount: d.correctCount,
  wrongCount: d.wrongCount,
  unsolvedCount: d.unsolvedCount,
  questionsMastered: d.questionsMastered,
  goalCompleted: d.goalCompleted,
  xpEarned: d.xpEarned,
);
UserProgress mapUserProgress(UserProgressDto d) => UserProgress(
  totalXp: d.totalXp,
  level: d.level,
  currentStreak: d.currentStreak,
  longestStreak: d.longestStreak,
  lastCompletedActivityDate: d.lastCompletedActivityDate == null
      ? null
      : DateTime.parse(d.lastCompletedActivityDate!),
  today: mapDailyProgress(d.today),
);
