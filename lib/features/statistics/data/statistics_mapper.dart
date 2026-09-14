import '../../question/data/question_mapper.dart';
import '../../question/domain/question.dart';
import '../domain/statistics_models.dart';
import 'statistics_dto.dart';

const statsRangeWire = {
  StatsRange.last7Days: 'LAST_7_DAYS',
  StatsRange.last30Days: 'LAST_30_DAYS',
  StatsRange.allTime: 'ALL_TIME',
};

GeneralStatistics mapGeneralStats(GeneralStatsDto d) => GeneralStatistics(
  totalQuestionsAdded: d.totalQuestionsAdded,
  totalReviews: d.totalReviews,
  correctCount: d.correctCount,
  wrongCount: d.wrongCount,
  unsolvedCount: d.unsolvedCount,
  successRate: d.successRate,
  activeQuestionCount: d.activeQuestionCount,
  masteredQuestionCount: d.masteredQuestionCount,
  currentStreak: d.currentStreak,
  longestStreak: d.longestStreak,
);

SubjectStatistics mapSubjectStats(SubjectStatsDto d) => SubjectStatistics(
  subjectId: d.subjectId,
  subjectName: d.subjectName,
  reviewCount: d.reviewCount,
  correctCount: d.correctCount,
  wrongCount: d.wrongCount,
  unsolvedCount: d.unsolvedCount,
  successRate: d.successRate,
  masteredCount: d.masteredCount,
);

TopicStatistics mapTopicStats(TopicStatsDto d) => TopicStatistics(
  topicId: d.topicId,
  topicName: d.topicName,
  subjectId: d.subjectId,
  subjectName: d.subjectName,
  reviewCount: d.reviewCount,
  correctCount: d.correctCount,
  wrongCount: d.wrongCount,
  unsolvedCount: d.unsolvedCount,
  successRate: d.successRate,
  masteredCount: d.masteredCount,
);

MistakeReason _reasonFromWire(String value) =>
    mistakeReasonWire.entries.where((e) => e.value == value).firstOrNull?.key ??
    MistakeReason.other;

MistakeReasonStatistics mapMistakeReasonStats(MistakeReasonStatsDto d) =>
    MistakeReasonStatistics(
      reason: _reasonFromWire(d.mistakeReason),
      count: d.count,
      percentage: d.percentage,
    );

LearningInsights mapInsights(InsightDto d) => LearningInsights(
  strongestSubjects: d.strongestSubjects.map(mapSubjectStats).toList(),
  weakestSubjects: d.weakestSubjects.map(mapSubjectStats).toList(),
  strongestTopics: d.strongestTopics.map(mapTopicStats).toList(),
  weakestTopics: d.weakestTopics.map(mapTopicStats).toList(),
  hardestTopics: d.hardestTopics.map(mapTopicStats).toList(),
  mostCommonMistakeReason: d.mostCommonMistakeReason == null
      ? null
      : _reasonFromWire(d.mostCommonMistakeReason!),
);
