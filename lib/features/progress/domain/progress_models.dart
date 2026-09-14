class DailyProgress {
  const DailyProgress({
    required this.activityDate,
    required this.reviewGoal,
    required this.effectiveReviewGoal,
    required this.reviewsCompleted,
    required this.correctCount,
    required this.wrongCount,
    required this.unsolvedCount,
    required this.questionsMastered,
    required this.goalCompleted,
    required this.xpEarned,
  });
  final DateTime activityDate;
  final int reviewGoal,
      effectiveReviewGoal,
      reviewsCompleted,
      correctCount,
      wrongCount,
      unsolvedCount,
      questionsMastered;
  final bool goalCompleted;
  final int xpEarned;
}

class UserProgress {
  const UserProgress({
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    required this.today,
    this.lastCompletedActivityDate,
  });
  final int totalXp, level, currentStreak, longestStreak;
  final DateTime? lastCompletedActivityDate;
  final DailyProgress today;
}
