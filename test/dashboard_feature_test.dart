import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/error/app_failure.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/features/dashboard/data/dashboard_dto.dart';
import 'package:hatora_mobile/features/dashboard/data/dashboard_mapper.dart';
import 'package:hatora_mobile/features/dashboard/data/dashboard_remote_data_source.dart';
import 'package:hatora_mobile/features/dashboard/data/dashboard_repository_impl.dart';
import 'package:hatora_mobile/features/dashboard/domain/dashboard_models.dart';
import 'package:hatora_mobile/features/dashboard/presentation/dashboard_view_model.dart';
import 'package:hatora_mobile/features/dashboard/presentation/dashboard_widgets.dart';

import 'support/fakes.dart';

Map<String, dynamic> dashboardJson({
  int dueCount = 5,
  int completed = 3,
  int effectiveGoal = 8,
  bool goalCompleted = false,
  String? activeSessionId,
  int? daysUntilExam,
  String? examDate,
}) => {
  'activeExam': {
    'examId': 'exam',
    'examEditionId': 'edition',
    'examName': 'Test sınavı',
    'examYear': 2026,
    'examDate': examDate,
    'daysUntilExam': daysUntilExam,
  },
  'review': {
    'dueCount': dueCount,
    'reviewsCompletedToday': completed,
    'effectiveReviewGoal': effectiveGoal,
    'goalCompleted': goalCompleted,
    'activeReviewSessionId': activeSessionId,
    'hasActiveReviewSession': activeSessionId != null,
  },
  'progress': {
    'totalXp': 120,
    'level': 2,
    'currentStreak': 4,
    'longestStreak': 8,
  },
  'questions': {'activeCount': 12, 'masteredCount': 3},
};

class ThrowingDashboardRemote extends DashboardRemoteDataSource {
  ThrowingDashboardRemote(this.error) : super(Dio());
  final Object error;
  @override
  Future<DashboardDto> get() async => throw error;
}

void main() {
  test('dashboard preserves actual calendar and upcoming counts; missing study is not fabricated', () {
    final json = dashboardJson();
    expect(mapDashboard(DashboardDto.fromJson(json)).study, isNull);
    json['study'] = {
      'today': '2026-10-12',
      'weekDays': [
        {
          'date': '2026-10-12',
          'reviewsCompleted': 0,
          'questionsAdded': 1,
          'goalCompleted': false,
        },
      ],
      'tomorrowQuestionCount': 5,
      'tomorrowTopicCount': 3,
    };
    final study = mapDashboard(DashboardDto.fromJson(json)).study!;
    expect(study.today, DateTime(2026, 10, 12));
    expect(study.weekDays.first.active, isTrue);
    expect(study.weekDays.first.goalCompleted, isFalse);
    expect(study.tomorrowTopicCount, 3);
    expect(study.tomorrowQuestionCount, 5);
  });

  test('full response maps without recomputing due/goal/streak/xp', () {
    final summary = mapDashboard(
      DashboardDto.fromJson(dashboardJson(activeSessionId: 'session-1')),
    );
    expect(summary.review.dueCount, 5);
    expect(summary.review.effectiveReviewGoal, 8);
    expect(summary.review.reviewsCompletedToday, 3);
    expect(summary.review.hasActiveReviewSession, true);
    expect(summary.review.activeReviewSessionId, 'session-1');
    expect(summary.progress.totalXp, 120);
    expect(summary.progress.currentStreak, 4);
    expect(summary.questions.activeCount, 12);
  });

  test('null exam date and null active session map safely', () {
    final summary = mapDashboard(DashboardDto.fromJson(dashboardJson()));
    expect(summary.activeExam.examDate, isNull);
    expect(summary.activeExam.daysUntilExam, isNull);
    expect(summary.review.activeReviewSessionId, isNull);
    expect(summary.review.hasActiveReviewSession, false);
  });

  test('zero due/effective goal state maps without local completion logic', () {
    final summary = mapDashboard(
      DashboardDto.fromJson(
        dashboardJson(dueCount: 0, completed: 0, effectiveGoal: 0),
      ),
    );
    expect(summary.review.effectiveReviewGoal, 0);
    expect(summary.review.goalCompleted, false);
  });

  test('repository normalizes failures', () async {
    final unauthorized = DioException(
      requestOptions: RequestOptions(),
      response: Response(requestOptions: RequestOptions(), statusCode: 401),
    );
    await expectLater(
      DashboardRepositoryImpl(ThrowingDashboardRemote(unauthorized))
          .getDashboard(),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.kind,
          'kind',
          FailureKind.unauthorized,
        ),
      ),
    );
  });

  test('view model loads, refreshes, fails and retries', () async {
    final repo = FakeDashboardRepository();
    final c = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    c.read(dashboardViewModelProvider);
    await flush();
    await flush();
    expect(c.read(dashboardViewModelProvider).summary?.progress.totalXp, 120);
    repo.failure = const AppFailure(FailureKind.server);
    await c.read(dashboardViewModelProvider.notifier).refresh();
    expect(c.read(dashboardViewModelProvider).phase, DashboardPhase.error);
    repo.failure = null;
    await c.read(dashboardViewModelProvider.notifier).retry();
    expect(c.read(dashboardViewModelProvider).phase, DashboardPhase.ready);
  });

  test(
    'continue review resolves answer option count and preserves session id',
    () async {
      final repo = FakeDashboardRepository()
        ..summary = DashboardSummary(
          activeExam: dashboardSummary.activeExam,
          review: const DashboardReviewSummary(
            dueCount: 0,
            reviewsCompletedToday: 0,
            effectiveReviewGoal: 0,
            goalCompleted: false,
            hasActiveReviewSession: true,
            activeReviewSessionId: 'session-9',
          ),
          progress: dashboardSummary.progress,
          questions: dashboardSummary.questions,
        );
      final c = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(repo),
          onboardingRepositoryProvider.overrideWithValue(
            FakeOnboardingRepository(),
          ),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
      );
      addTearDown(c.dispose);
      c.read(dashboardViewModelProvider);
      await flush();
      await flush();
      await c.read(dashboardViewModelProvider.notifier).continueReview();
      final session = c.read(dashboardViewModelProvider).continueSession;
      expect(session?.sessionId, 'session-9');
      expect(session?.answerOptionCount, exam.answerOptionCount);
    },
  );

  testWidgets('today progress shows 3 / 8, never 3 / 5', (tester) async {
    const review = DashboardReviewSummary(
      dueCount: 5,
      reviewsCompletedToday: 3,
      effectiveReviewGoal: 8,
      goalCompleted: false,
      hasActiveReviewSession: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: DashboardReviewProgressCard(review: review)),
      ),
    );
    expect(find.text('3 / 8'), findsOneWidget);
    expect(find.text('3 / 5'), findsNothing);
  });

  test('exam countdown label derivation', () {
    expect(examCountdownLabel(42), '42 gün kaldı');
    expect(examCountdownLabel(0), 'Bugün');
    expect(examCountdownLabel(-3), 'Sınav tarihi geçti');
    expect(examCountdownLabel(null), 'Sınav tarihi belirtilmemiş');
  });

  test('review CTA label derivation', () {
    expect(
      reviewCtaLabel(
        const DashboardReviewSummary(
          dueCount: 0,
          reviewsCompletedToday: 0,
          effectiveReviewGoal: 0,
          goalCompleted: false,
          hasActiveReviewSession: true,
          activeReviewSessionId: 's',
        ),
      ),
      'Tekrara Devam Et',
    );
    expect(
      reviewCtaLabel(
        const DashboardReviewSummary(
          dueCount: 5,
          reviewsCompletedToday: 0,
          effectiveReviewGoal: 5,
          goalCompleted: false,
          hasActiveReviewSession: false,
        ),
      ),
      'Tekrara Başla',
    );
    expect(
      reviewCtaLabel(
        const DashboardReviewSummary(
          dueCount: 0,
          reviewsCompletedToday: 0,
          effectiveReviewGoal: 0,
          goalCompleted: false,
          hasActiveReviewSession: false,
        ),
      ),
      'Bugünlük tekrarın yok',
    );
  });
}
