import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/error/app_failure.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/features/progress/data/progress_dto.dart';
import 'package:hatora_mobile/features/progress/data/progress_mapper.dart';
import 'package:hatora_mobile/features/progress/data/progress_remote_data_source.dart';
import 'package:hatora_mobile/features/progress/data/progress_repository_impl.dart';
import 'package:hatora_mobile/features/progress/domain/progress_models.dart';
import 'package:hatora_mobile/features/progress/presentation/progress_view_model.dart';
import 'package:hatora_mobile/features/progress/presentation/progress_widgets.dart';

import 'support/fakes.dart';

Map<String, dynamic> json({
  int xp = 120,
  bool complete = false,
  int effective = 3,
  int done = 2,
}) => {
  'totalXp': xp,
  'level': 2,
  'currentStreak': 4,
  'longestStreak': 8,
  'lastCompletedActivityDate': null,
  'today': {
    'activityDate': '2026-09-13',
    'reviewGoal': 10,
    'effectiveReviewGoal': effective,
    'reviewsCompleted': done,
    'correctCount': 1,
    'wrongCount': 1,
    'unsolvedCount': 0,
    'questionsMastered': 0,
    'goalCompleted': complete,
    'xpEarned': 5,
  },
};

class ThrowingProgressRemote extends ProgressRemoteDataSource {
  ThrowingProgressRemote(this.error) : super(Dio());
  final Object error;
  @override
  Future<UserProgressDto> getProgress() async => throw error;
}

void main() {
  test('full and zero progress responses map without client rules', () {
    final p = mapUserProgress(UserProgressDto.fromJson(json()));
    expect(p.totalXp, 120);
    expect(p.lastCompletedActivityDate, isNull);
    expect(p.today.effectiveReviewGoal, 3);
    expect(p.today.goalCompleted, false);
    final zero = mapUserProgress(
      UserProgressDto.fromJson(json(xp: 0, effective: 0, done: 0)),
    );
    expect(zero.totalXp, 0);
    expect(zero.today.effectiveReviewGoal, 0);
    expect(zero.today.goalCompleted, false);
  });
  test(
    'repository normalizes unauthorized, network, and malformed failures',
    () async {
      final unauthorized = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 401),
      );
      await expectLater(
        ProgressRepositoryImpl(ThrowingProgressRemote(unauthorized))
            .getProgress(),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.unauthorized,
          ),
        ),
      );
      await expectLater(
        ProgressRepositoryImpl(
          ThrowingProgressRemote(
            DioException(requestOptions: RequestOptions()),
          ),
        ).getProgress(),
        throwsA(
          isA<AppFailure>().having((e) => e.kind, 'kind', FailureKind.network),
        ),
      );
      await expectLater(
        ProgressRepositoryImpl(ThrowingProgressRemote(const FormatException()))
            .getProgress(),
        throwsA(
          isA<AppFailure>().having((e) => e.kind, 'kind', FailureKind.unknown),
        ),
      );
    },
  );
  test(
    'view model loads, fails, retries and uses refreshed backend XP',
    () async {
      final repo = FakeProgressRepository();
      final c = ProviderContainer(
        overrides: [progressRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      c.read(progressViewModelProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(progressViewModelProvider).progress?.totalXp, 120);
      repo.failure = const AppFailure(FailureKind.server);
      await c.read(progressViewModelProvider.notifier).refresh();
      expect(c.read(progressViewModelProvider).phase, ProgressPhase.error);
      repo.failure = null;
      repo.progress = UserProgress(
        totalXp: 999,
        level: 7,
        currentStreak: 12,
        longestStreak: 13,
        lastCompletedActivityDate: null,
        today: dailyProgress,
      );
      await c.read(progressViewModelProvider.notifier).retry();
      expect(c.read(progressViewModelProvider).progress?.totalXp, 999);
      expect(c.read(progressViewModelProvider).progress?.currentStreak, 12);
    },
  );
  testWidgets('effective goal displays 2 / 3 and never 2 / 10', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: TodayProgressCard(progress: dailyProgress)),
      ),
    );
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('2 / 10'), findsNothing);
  });
  testWidgets('zero due false state is not rendered completed', (tester) async {
    final zero = DailyProgress(
      activityDate: DateTime(2026),
      reviewGoal: 10,
      effectiveReviewGoal: 0,
      reviewsCompleted: 0,
      correctCount: 0,
      wrongCount: 0,
      unsolvedCount: 0,
      questionsMastered: 0,
      goalCompleted: false,
      xpEarned: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: TodayProgressCard(progress: zero)),
      ),
    );
    expect(find.text('Bugün tekrar bekleyen sorun yok.'), findsOneWidget);
    expect(find.text('Bugünkü hedef tamamlandı.'), findsNothing);
  });
  testWidgets(
    'overview renders backend XP level streak and completed state on small large-text phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final complete = UserProgress(
        totalXp: 777,
        level: 6,
        currentStreak: 9,
        longestStreak: 14,
        lastCompletedActivityDate: null,
        today: DailyProgress(
          activityDate: DateTime(2026),
          reviewGoal: 10,
          effectiveReviewGoal: 3,
          reviewsCompleted: 3,
          correctCount: 2,
          wrongCount: 1,
          unsolvedCount: 0,
          questionsMastered: 1,
          goalCompleted: true,
          xpEarned: 20,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: ProgressOverview(progress: complete),
              ),
            ),
          ),
        ),
      );
      expect(find.text('777 XP'), findsOneWidget);
      expect(find.text('Seviye 6'), findsOneWidget);
      expect(find.text('9 gün'), findsOneWidget);
      expect(find.text('Bugünkü hedef tamamlandı.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
