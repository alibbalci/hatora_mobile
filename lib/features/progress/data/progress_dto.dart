class DailyProgressDto {
  DailyProgressDto.fromJson(Map<String, dynamic> json)
    : activityDate = json['activityDate'] as String,
      reviewGoal = json['reviewGoal'] as int,
      effectiveReviewGoal = json['effectiveReviewGoal'] as int,
      reviewsCompleted = json['reviewsCompleted'] as int,
      correctCount = json['correctCount'] as int,
      wrongCount = json['wrongCount'] as int,
      unsolvedCount = json['unsolvedCount'] as int,
      questionsMastered = json['questionsMastered'] as int,
      goalCompleted = json['goalCompleted'] as bool,
      xpEarned = (json['xpEarned'] as num).toInt();
  final String activityDate;
  final int reviewGoal,
      effectiveReviewGoal,
      reviewsCompleted,
      correctCount,
      wrongCount,
      unsolvedCount,
      questionsMastered,
      xpEarned;
  final bool goalCompleted;
}

class UserProgressDto {
  UserProgressDto.fromJson(Map<String, dynamic> json)
    : totalXp = (json['totalXp'] as num).toInt(),
      level = json['level'] as int,
      currentStreak = json['currentStreak'] as int,
      longestStreak = json['longestStreak'] as int,
      lastCompletedActivityDate = json['lastCompletedActivityDate'] as String?,
      today = DailyProgressDto.fromJson(json['today'] as Map<String, dynamic>);
  final int totalXp, level, currentStreak, longestStreak;
  final String? lastCompletedActivityDate;
  final DailyProgressDto today;
}
