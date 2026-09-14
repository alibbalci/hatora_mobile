import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/app.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/app/router.dart';
import 'package:hatora_mobile/app/routes.dart';
import 'package:hatora_mobile/app/shell.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/core/widget/components.dart';
import 'package:hatora_mobile/features/dashboard/domain/dashboard_models.dart';
import 'package:hatora_mobile/features/question/domain/question.dart';
import 'package:hatora_mobile/features/question/presentation/my_questions_screens.dart';

import 'support/fakes.dart';

void main() {
  ProviderContainer setup({bool signedIn = true}) {
    final auth = FakeAuthRepository()..session = signedIn ? user : null;
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
          FakeDashboardRepository(),
        ),
        statisticsRepositoryProvider.overrideWithValue(
          FakeStatisticsRepository(),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      auth.events.close();
    });
    return container;
  }

  testWidgets(
    'bottom navigation renders one NavigationBar with all 5 destinations',
    (tester) async {
      final container = setup();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HatoraApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      for (final label in [
        'Ana Sayfa',
        'Plan',
        'İstatistik',
        'Sorularım',
        'Profil',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(AppShell.paths, hasLength(5));
    },
  );

  testWidgets(
    'Home primary CTA reflects due count and disables when nothing is due',
    (tester) async {
      final container = setup();
      final repo = container.read(
        dashboardRepositoryProvider,
      ) as FakeDashboardRepository;
      repo.summary = DashboardSummary(
        activeExam: dashboardSummary.activeExam,
        review: const DashboardReviewSummary(
          dueCount: 0,
          reviewsCompletedToday: 0,
          effectiveReviewGoal: 0,
          goalCompleted: false,
          hasActiveReviewSession: false,
        ),
        progress: dashboardSummary.progress,
        questions: dashboardSummary.questions,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HatoraApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bugünlük tekrarın yok'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'question status chip surfaces mastered/archived/active with icon and text',
    (tester) async {
      Widget chipFor(QuestionStatus status) => MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: QuestionStatusChip(
            question: QuestionSummary(
              id: 'q',
              topicId: 't',
              topicName: 'Türev',
              subjectId: 's',
              subjectName: 'Matematik',
              examCode: 'TYT',
              correctAnswer: 'A',
              difficulty: Difficulty.medium,
              mistakeReason: MistakeReason.other,
              reviewStage: 0,
              status: status,
              createdAt: DateTime.utc(2026, 9, 13),
            ),
          ),
        ),
      );
      await tester.pumpWidget(chipFor(QuestionStatus.mastered));
      expect(find.text('Öğrenildi'), findsOneWidget);
      await tester.pumpWidget(chipFor(QuestionStatus.archived));
      expect(find.text('Arşivlendi'), findsOneWidget);
      await tester.pumpWidget(chipFor(QuestionStatus.active));
      expect(find.text('Tekrar tarihi yok'), findsOneWidget);
    },
  );

  testWidgets(
    'answer options reveal correct/wrong state with icon, not color alone',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: AnswerOptions(
              count: 4,
              selected: 'B',
              onSelected: (_) {},
              correctAnswer: 'C',
              revealed: true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      // The correct/selected-wrong buttons are disabled once revealed.
      final buttons = tester.widgetList<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(buttons.every((b) => b.onPressed == null), isTrue);
    },
  );

  testWidgets(
    'Home and My Questions survive 1.3x text scale without crashing',
    (tester) async {
      final container = setup();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: const HatoraApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      container.read(routerProvider).go(Routes.myQuestions);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      container.read(routerProvider).go(Routes.statistics);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
