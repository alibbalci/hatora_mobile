import 'statistics_models.dart';
import 'statistics_repository.dart';

class GetStatisticsUseCase {
  const GetStatisticsUseCase(this.repository);
  final StatisticsRepository repository;
  Future<StatisticsBundle> call(StatsRange range) async {
    final results = await Future.wait([
      repository.getGeneral(range),
      repository.getSubjects(range),
      repository.getTopics(range),
      repository.getMistakeReasons(range),
      repository.getInsights(range),
    ]);
    return StatisticsBundle(
      general: results[0] as GeneralStatistics,
      subjects: results[1] as List<SubjectStatistics>,
      topics: results[2] as List<TopicStatistics>,
      mistakeReasons: results[3] as List<MistakeReasonStatistics>,
      insights: results[4] as LearningInsights,
    );
  }
}
