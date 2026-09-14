import 'statistics_models.dart';

abstract interface class StatisticsRepository {
  Future<GeneralStatistics> getGeneral(StatsRange range);
  Future<List<SubjectStatistics>> getSubjects(StatsRange range);
  Future<List<TopicStatistics>> getTopics(StatsRange range);
  Future<List<MistakeReasonStatistics>> getMistakeReasons(StatsRange range);
  Future<LearningInsights> getInsights(StatsRange range);
}
