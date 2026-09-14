import 'package:dio/dio.dart';

import '../domain/statistics_models.dart';
import 'statistics_dto.dart';
import 'statistics_mapper.dart';

class StatisticsRemoteDataSource {
  const StatisticsRemoteDataSource(this.dio);
  final Dio dio;

  Future<GeneralStatsDto> general(StatsRange range) async =>
      GeneralStatsDto.fromJson(
        (await dio.get<Map<String, dynamic>>(
          '/api/statistics/general',
          queryParameters: {'range': statsRangeWire[range]},
        )).data!,
      );

  Future<List<SubjectStatsDto>> subjects(StatsRange range) async {
    final response = await dio.get<List<dynamic>>(
      '/api/statistics/subjects',
      queryParameters: {'range': statsRangeWire[range]},
    );
    return response.data!
        .map((e) => SubjectStatsDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopicStatsDto>> topics(StatsRange range) async {
    final response = await dio.get<List<dynamic>>(
      '/api/statistics/topics',
      queryParameters: {'range': statsRangeWire[range]},
    );
    return response.data!
        .map((e) => TopicStatsDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MistakeReasonStatsDto>> mistakeReasons(StatsRange range) async {
    final response = await dio.get<List<dynamic>>(
      '/api/statistics/mistake-reasons',
      queryParameters: {'range': statsRangeWire[range]},
    );
    return response.data!
        .map((e) => MistakeReasonStatsDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InsightDto> insights(StatsRange range) async => InsightDto.fromJson(
    (await dio.get<Map<String, dynamic>>(
      '/api/statistics/insights',
      queryParameters: {'range': statsRangeWire[range]},
    )).data!,
  );
}
