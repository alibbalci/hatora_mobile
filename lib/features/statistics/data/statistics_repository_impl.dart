import '../../../core/error/failure_mapper.dart';
import '../domain/statistics_models.dart';
import '../domain/statistics_repository.dart';
import 'statistics_mapper.dart';
import 'statistics_remote_data_source.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  const StatisticsRepositoryImpl(this.remote);
  final StatisticsRemoteDataSource remote;

  @override
  Future<GeneralStatistics> getGeneral(StatsRange range) =>
      repositoryCall(() async => mapGeneralStats(await remote.general(range)));

  @override
  Future<List<SubjectStatistics>> getSubjects(StatsRange range) =>
      repositoryCall(
        () async =>
            (await remote.subjects(range)).map(mapSubjectStats).toList(),
      );

  @override
  Future<List<TopicStatistics>> getTopics(StatsRange range) => repositoryCall(
    () async => (await remote.topics(range)).map(mapTopicStats).toList(),
  );

  @override
  Future<List<MistakeReasonStatistics>> getMistakeReasons(StatsRange range) =>
      repositoryCall(
        () async =>
            (await remote.mistakeReasons(range))
                .map(mapMistakeReasonStats)
                .toList(),
      );

  @override
  Future<LearningInsights> getInsights(StatsRange range) =>
      repositoryCall(() async => mapInsights(await remote.insights(range)));
}
