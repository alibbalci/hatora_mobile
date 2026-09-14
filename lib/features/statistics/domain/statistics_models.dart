import '../../question/domain/question.dart';

enum StatsRange { last7Days, last30Days, allTime }

class GeneralStatistics {
  const GeneralStatistics({
    required this.totalQuestionsAdded,
    required this.totalReviews,
    required this.correctCount,
    required this.wrongCount,
    required this.unsolvedCount,
    required this.successRate,
    required this.activeQuestionCount,
    required this.masteredQuestionCount,
    required this.currentStreak,
    required this.longestStreak,
  });
  final int totalQuestionsAdded,
      totalReviews,
      correctCount,
      wrongCount,
      unsolvedCount,
      activeQuestionCount,
      masteredQuestionCount,
      currentStreak,
      longestStreak;
  final double successRate;
}

class SubjectStatistics {
  const SubjectStatistics({
    required this.subjectId,
    required this.subjectName,
    required this.reviewCount,
    required this.correctCount,
    required this.wrongCount,
    required this.unsolvedCount,
    required this.successRate,
    required this.masteredCount,
  });
  final String subjectId, subjectName;
  final int reviewCount, correctCount, wrongCount, unsolvedCount, masteredCount;
  final double successRate;
}

class TopicStatistics {
  const TopicStatistics({
    required this.topicId,
    required this.topicName,
    required this.subjectId,
    required this.subjectName,
    required this.reviewCount,
    required this.correctCount,
    required this.wrongCount,
    required this.unsolvedCount,
    required this.successRate,
    required this.masteredCount,
  });
  final String topicId, topicName, subjectId, subjectName;
  final int reviewCount, correctCount, wrongCount, unsolvedCount, masteredCount;
  final double successRate;
}

class MistakeReasonStatistics {
  const MistakeReasonStatistics({
    required this.reason,
    required this.count,
    required this.percentage,
  });
  final MistakeReason reason;
  final int count;
  final double percentage;
}

class LearningInsights {
  const LearningInsights({
    required this.strongestSubjects,
    required this.weakestSubjects,
    required this.strongestTopics,
    required this.weakestTopics,
    required this.hardestTopics,
    this.mostCommonMistakeReason,
  });
  final List<SubjectStatistics> strongestSubjects, weakestSubjects;
  final List<TopicStatistics> strongestTopics, weakestTopics, hardestTopics;
  final MistakeReason? mostCommonMistakeReason;
  bool get hasRankings =>
      strongestSubjects.isNotEmpty ||
      weakestSubjects.isNotEmpty ||
      strongestTopics.isNotEmpty ||
      weakestTopics.isNotEmpty ||
      hardestTopics.isNotEmpty;
}

class StatisticsBundle {
  const StatisticsBundle({
    required this.general,
    required this.subjects,
    required this.topics,
    required this.mistakeReasons,
    required this.insights,
  });
  final GeneralStatistics general;
  final List<SubjectStatistics> subjects;
  final List<TopicStatistics> topics;
  final List<MistakeReasonStatistics> mistakeReasons;
  final LearningInsights insights;
}
