import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/features/dashboard/domain/dashboard_models.dart';
import 'package:hatora_mobile/features/home/presentation/home_focus_card.dart';
import 'package:hatora_mobile/features/home/presentation/home_exam_summary.dart';
import 'package:hatora_mobile/features/home/presentation/home_reference_widgets.dart';
import 'package:hatora_mobile/features/catalog/domain/exam_schedule.dart';

void main() {
  testWidgets(
    'weekly strip uses actual past activity and never marks future as worked',
    (tester) async {
      final study = DashboardStudySummary(
        today: DateTime(2026, 10, 14),
        weekDays: List.generate(
          7,
          (i) => DashboardStudyDay(
            date: DateTime(2026, 10, 12 + i),
            reviewsCompleted: i == 2 ? 2 : 0,
            questionsAdded: i == 0 || i == 6 ? 1 : 0,
            goalCompleted: i == 2,
          ),
        ),
        tomorrowQuestionCount: 5,
        tomorrowTopicCount: 3,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: HomeWeekActivity(study: study)),
        ),
      );
      expect(find.text('2 / 7 gün'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    },
  );
  testWidgets('tomorrow action shows server topic count and routes on tap', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: HomeQuickActions(
            onAdd: () {},
            onPlan: () => opens++,
            study: DashboardStudySummary(
              today: DateTime(2026, 10, 12),
              weekDays: const [],
              tomorrowQuestionCount: 5,
              tomorrowTopicCount: 3,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Yarın 3 konu'), findsOneWidget);
    await tester.tap(find.text('Planıma bak'));
    expect(opens, 1);
  });
  testWidgets(
    'personal header handles long name and large text on small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var profiles = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: HomeHeader(
                  name: 'Abdülkadir Çokuzunbirsoyadı',
                  today: DateTime(2026, 10, 12),
                  streak: 4,
                  onProfile: () => profiles++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      expect(profiles, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('exam summary removes repeated full name and fits large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: HomeExamSummaryContent(
                  exam: const DashboardActiveExam(
                    examId: 'e',
                    examEditionId: 'ed',
                    examName: 'KPSS Ortaöğretim (Genel Yetenek–Genel Kültür)',
                    examYear: 2028,
                  ),
                  sessions: [
                    ExamSessionSchedule(
                      code: 'GY_GK',
                      name: 'Genel Yetenek–Genel Kültür',
                      estimatedDate: DateTime(2028, 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('KPSS Ortaöğretim · 2028'), findsOneWidget);
    expect(find.text('Yaklaşık Ekim 2028'), findsOneWidget);
    expect(find.text('Genel Yetenek–Genel Kültür'), findsNothing);
    expect(find.text('Sınav takvimi'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('past exam stays hidden even if countdown is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeExamSummaryContent(
            exam: DashboardActiveExam(
              examId: 'e',
              examEditionId: 'ed',
              examName: 'Eski sınav',
              examYear: 2020,
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Eski sınav'), findsNothing);
  });

  for (final width in [320.0, 430.0]) {
    testWidgets(
      'focus card fits width $width with large text and starts review',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var starts = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 800),
                textScaler: const TextScaler.linear(1.8),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: HomeFocusCard(
                      review: const DashboardReviewSummary(
                        dueCount: 8,
                        reviewsCompletedToday: 2,
                        effectiveReviewGoal: 10,
                        goalCompleted: false,
                        hasActiveReviewSession: false,
                      ),
                      hasQuestions: true,
                      label: 'Tekrara Başla',
                      onPressed: () => starts++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Bugün 8 soruyla\nbir adım daha.'), findsOneWidget);
        await tester.ensureVisible(find.text('Tekrara Başla'));
        await tester.tap(find.text('Tekrara Başla'));
        expect(starts, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'new learner gets an active first-question action without empty progress',
    (tester) async {
      var adds = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: HomeFocusCard(
              review: const DashboardReviewSummary(
                dueCount: 0,
                reviewsCompletedToday: 0,
                effectiveReviewGoal: 0,
                goalCompleted: false,
                hasActiveReviewSession: false,
              ),
              hasQuestions: false,
              label: 'Yeni soru ekle',
              onPressed: () => adds++,
            ),
          ),
        ),
      );
      expect(find.text('İlk soruyla\nbaşlayalım.'), findsOneWidget);
      expect(find.text('0 / 0 soru'), findsNothing);
      await tester.tap(find.text('Yeni soru ekle'));
      expect(adds, 1);
    },
  );
}
