import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:hatora_mobile/app/router.dart';
import 'package:hatora_mobile/app/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/app.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/error/app_failure.dart';
import 'package:hatora_mobile/features/dashboard/domain/dashboard_models.dart';
import 'package:hatora_mobile/features/review/domain/review_models.dart';
import 'package:hatora_mobile/features/review/domain/review_repository.dart';

import 'support/fakes.dart';

class FakeReviewRepository implements ReviewRepository {
  ReviewSetupData setup = const ReviewSetupData(totalDue: 3, subjects: []);
  AppFailure nextItemFailure = const AppFailure(FailureKind.network);
  @override
  Future<ReviewSetupData> getSetup() async => setup;
  @override
  Future<List<DueCountItem>> getDueCounts({String? subjectId}) async => [];
  @override
  Future<ReviewSession> createOrResume({
    String? subjectId,
    String? topicId,
  }) async => throw const AppFailure(FailureKind.network);
  @override
  Future<List<ReviewSession>> getSessions({
    ReviewSessionStatus? status,
  }) async => [];
  @override
  Future<ReviewSession> getSession(String id) async =>
      throw const AppFailure(FailureKind.network);
  @override
  Future<NextReviewItem?> getNextItem(String sessionId) async =>
      throw nextItemFailure;
  @override
  Future<AnswerResult> submitAnswer(
    String itemId, {
    String? selectedAnswer,
    required bool unsolved,
  }) async => throw const AppFailure(FailureKind.network);
  @override
  Future<ReviewImage> loadImage(Uri uri) async =>
      throw const AppFailure(FailureKind.network);
}

void main() {
  ProviderContainer setup({required DashboardSummary dashboard}) {
    final auth = FakeAuthRepository()..session = user;
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        onboardingRepositoryProvider.overrideWithValue(
          FakeOnboardingRepository(),
        ),
        questionRepositoryProvider.overrideWithValue(FakeQuestionRepository()),
        imagePickerProvider.overrideWithValue(FakePicker()),
        progressRepositoryProvider.overrideWithValue(FakeProgressRepository()),
        dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository()..summary = dashboard,
        ),
        reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
      ],
    );
    addTearDown(() {
      container.dispose();
      auth.events.close();
    });
    return container;
  }

  testWidgets('Plan tab shows live review progress and opens review setup', (
    tester,
  ) async {
    final container = setup(
      dashboard: DashboardSummary(
        activeExam: dashboardSummary.activeExam,
        review: const DashboardReviewSummary(
          dueCount: 5,
          reviewsCompletedToday: 2,
          effectiveReviewGoal: 5,
          goalCompleted: false,
          hasActiveReviewSession: false,
        ),
        progress: dashboardSummary.progress,
        questions: dashboardSummary.questions,
      ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HatoraApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go(Routes.plan);
    await tester.pumpAndSettle();
    expect(find.text('Çalışma planı'), findsOneWidget);
    expect(find.text('5 soru tekrar bekliyor'), findsOneWidget);
    await tester.ensureVisible(find.text('Tekrara Başla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tekrara Başla'));
    await tester.pumpAndSettle();
    expect(find.text('Bugünün tekrarı'), findsOneWidget);
  });
  testWidgets('Plan shows actionable empty state when nothing is due', (
    tester,
  ) async {
    final container = setup(
      dashboard: DashboardSummary(
        activeExam: dashboardSummary.activeExam,
        review: const DashboardReviewSummary(
          dueCount: 0,
          reviewsCompletedToday: 0,
          effectiveReviewGoal: 0,
          goalCompleted: true,
          hasActiveReviewSession: false,
        ),
        progress: dashboardSummary.progress,
        questions: dashboardSummary.questions,
      ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HatoraApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go(Routes.plan);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Bugün serbestsin'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bugün serbestsin'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Soru ekle'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Soru ekle'), findsOneWidget);
  });

  testWidgets('Dashboard loads, user taps Start Review, Review route opens', (
    tester,
  ) async {
    final container = setup(
      dashboard: DashboardSummary(
        activeExam: dashboardSummary.activeExam,
        review: const DashboardReviewSummary(
          dueCount: 5,
          reviewsCompletedToday: 0,
          effectiveReviewGoal: 5,
          goalCompleted: false,
          hasActiveReviewSession: false,
        ),
        progress: dashboardSummary.progress,
        questions: dashboardSummary.questions,
      ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HatoraApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tekrara Başla'), findsOneWidget);
    await tester.ensureVisible(find.text('Tekrara Başla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tekrara Başla'));
    await tester.pumpAndSettle();
    expect(find.text('Bugünün tekrarı'), findsOneWidget);
  });

  testWidgets(
    'Dashboard has activeReviewSessionId, user taps Continue Review, existing session route opens',
    (tester) async {
      final container = setup(
        dashboard: DashboardSummary(
          activeExam: dashboardSummary.activeExam,
          review: const DashboardReviewSummary(
            dueCount: 0,
            reviewsCompletedToday: 2,
            effectiveReviewGoal: 5,
            goalCompleted: false,
            hasActiveReviewSession: true,
            activeReviewSessionId: 'session-9',
          ),
          progress: dashboardSummary.progress,
          questions: dashboardSummary.questions,
        ),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HatoraApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tekrara Devam Et'), findsOneWidget);
      await tester.ensureVisible(find.text('Tekrara Devam Et'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tekrara Devam Et'));
      await tester.pumpAndSettle();
      expect(find.text('Tekrar'), findsOneWidget);
    },
  );
}
