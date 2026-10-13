import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/error/app_failure.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/features/question/data/question_mapper.dart';
import 'package:hatora_mobile/features/question/domain/question.dart';
import 'package:hatora_mobile/features/statistics/data/statistics_dto.dart';
import 'package:hatora_mobile/features/statistics/data/statistics_mapper.dart';
import 'package:hatora_mobile/features/statistics/data/statistics_remote_data_source.dart';
import 'package:hatora_mobile/features/statistics/data/statistics_repository_impl.dart';
import 'package:hatora_mobile/features/statistics/domain/statistics_models.dart';
import 'package:hatora_mobile/features/statistics/presentation/statistics_view_model.dart';
import 'package:hatora_mobile/features/statistics/presentation/statistics_widgets.dart';

import 'support/fakes.dart';

void main() {
  test('general stats DTO maps every backend field without recomputation', () {
    final stats = mapGeneralStats(
      GeneralStatsDto.fromJson({
        'totalQuestionsAdded': 20,
        'totalReviews': 10,
        'correctCount': 6,
        'wrongCount': 3,
        'unsolvedCount': 1,
        'successRate': 60.0,
        'activeQuestionCount': 15,
        'masteredQuestionCount': 5,
        'currentStreak': 4,
        'longestStreak': 8,
      }),
    );
    expect(stats.successRate, 60.0);
    expect(stats.currentStreak, 4);
    expect(stats.masteredQuestionCount, 5);
  });

  test('subject/topic stats DTOs map zero values safely', () {
    final subject = mapSubjectStats(
      SubjectStatsDto.fromJson({
        'subjectId': 's',
        'subjectName': 'Matematik',
        'reviewCount': 0,
        'correctCount': 0,
        'wrongCount': 0,
        'unsolvedCount': 0,
        'successRate': 0.0,
        'masteredCount': 0,
      }),
    );
    expect(subject.successRate, 0.0);
    final topic = mapTopicStats(
      TopicStatsDto.fromJson({
        'topicId': 't',
        'topicName': 'Türev',
        'subjectId': 's',
        'subjectName': 'Matematik',
        'reviewCount': 5,
        'correctCount': 3,
        'wrongCount': 1,
        'unsolvedCount': 1,
        'successRate': 60.0,
        'masteredCount': 1,
      }),
    );
    expect(topic.subjectName, 'Matematik');
  });

  test('mistake reason DTO maps all 7 reasons including zero counts', () {
    for (final reason in MistakeReason.values) {
      final stats = mapMistakeReasonStats(
        MistakeReasonStatsDto.fromJson({
          'mistakeReason': mistakeReasonWire[reason],
          'count': 0,
          'percentage': 0.0,
        }),
      );
      expect(stats.reason, reason);
      expect(stats.count, 0);
    }
  });

  test('insight DTO maps empty rankings and null most common reason', () {
    final insights = mapInsights(
      InsightDto.fromJson({
        'strongestSubjects': [],
        'weakestSubjects': [],
        'strongestTopics': [],
        'weakestTopics': [],
        'hardestTopics': [],
        'mostCommonMistakeReason': null,
      }),
    );
    expect(insights.hasRankings, false);
    expect(insights.mostCommonMistakeReason, isNull);
  });

  test('range enum maps to exact backend wire values', () {
    expect(statsRangeWire[StatsRange.last7Days], 'LAST_7_DAYS');
    expect(statsRangeWire[StatsRange.last30Days], 'LAST_30_DAYS');
    expect(statsRangeWire[StatsRange.allTime], 'ALL_TIME');
  });

  test(
    'repository sends range as a query parameter to every endpoint',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = _RecordingAdapter();
      final remote = StatisticsRemoteDataSource(dio);
      final repo = StatisticsRepositoryImpl(remote);
      await repo.getGeneral(StatsRange.last30Days);
      expect(_RecordingAdapter.lastOptions?.path, '/api/statistics/general');
      expect(
        _RecordingAdapter.lastOptions?.queryParameters['range'],
        'LAST_30_DAYS',
      );
    },
  );

  test('repository normalizes unauthorized failures', () async {
    final dio = Dio();
    dio.httpClientAdapter = _FailingAdapter(401);
    final repo = StatisticsRepositoryImpl(StatisticsRemoteDataSource(dio));
    await expectLater(
      repo.getGeneral(StatsRange.last7Days),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.kind,
          'kind',
          FailureKind.unauthorized,
        ),
      ),
    );
  });

  test(
    'view model loads default range, changes range, refreshes and retries',
    () async {
      final repo = FakeStatisticsRepository();
      final c = ProviderContainer(
        overrides: [statisticsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      c.read(statisticsViewModelProvider);
      await flush();
      await flush();
      expect(c.read(statisticsViewModelProvider).range, StatsRange.last7Days);
      expect(repo.lastRange, StatsRange.last7Days);
      await c
          .read(statisticsViewModelProvider.notifier)
          .changeRange(StatsRange.allTime);
      expect(repo.lastRange, StatsRange.allTime);
      expect(c.read(statisticsViewModelProvider).range, StatsRange.allTime);
      repo.failure = const AppFailure(FailureKind.server);
      await c.read(statisticsViewModelProvider.notifier).refresh();
      expect(c.read(statisticsViewModelProvider).phase, StatisticsPhase.error);
      repo.failure = null;
      await c.read(statisticsViewModelProvider.notifier).retry();
      expect(c.read(statisticsViewModelProvider).phase, StatisticsPhase.ready);
    },
  );

  testWidgets('range selector shows exact Turkish labels and emits selection', (
    tester,
  ) async {
    StatsRange? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: StatsRangeSelector(
            selected: StatsRange.last7Days,
            onChanged: (r) => selected = r,
          ),
        ),
      ),
    );
    expect(find.text('7 gün'), findsOneWidget);
    expect(find.text('30 gün'), findsOneWidget);
    expect(find.text('Tümü'), findsOneWidget);
    await tester.tap(find.text('Tümü'));
    expect(selected, StatsRange.allTime);
  });

  testWidgets('empty insight state shows the exact required message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: LearningInsightsCard(insights: statisticsBundle.insights),
        ),
      ),
    );
    expect(find.text('Henüz yeterli tekrar verisi yok.'), findsOneWidget);
  });

  testWidgets(
    'general overview renders backend values without recomputing rate',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: GeneralOverviewCard(stats: generalStatistics),
          ),
        ),
      );
      expect(find.text('%60.0'), findsOneWidget);
      expect(find.text('4 gün'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _RecordingAdapter implements HttpClientAdapter {
  static RequestOptions? lastOptions;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      '{"totalQuestionsAdded":0,"totalReviews":0,"correctCount":0,'
      '"wrongCount":0,"unsolvedCount":0,"successRate":0.0,'
      '"activeQuestionCount":0,"masteredQuestionCount":0,'
      '"currentStreak":0,"longestStreak":0}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _FailingAdapter implements HttpClientAdapter {
  _FailingAdapter(this.statusCode);
  final int statusCode;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{}',
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
