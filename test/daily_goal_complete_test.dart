import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/features/progress/domain/progress_models.dart';
import 'package:hatora_mobile/features/progress/presentation/daily_goal_complete_screen.dart';

import 'support/fakes.dart';

DailyProgress day({int goal = 10}) => DailyProgress(
  activityDate: DateTime(2026, 10, 12),
  reviewGoal: 10,
  effectiveReviewGoal: goal,
  reviewsCompleted: 10,
  correctCount: 8,
  wrongCount: 2,
  unsolvedCount: 0,
  questionsMastered: 1,
  goalCompleted: true,
  xpEarned: 20,
);
void main() {
  test(
    'daily celebration is once per user and date, and never for a zero goal',
    () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final gate = c.read(dailyCelebrationGateProvider.notifier);
      expect(gate.claim('u', day(goal: 0)), false);
      expect(gate.claim('u', day()), true);
      expect(gate.claim('u', day()), false);
      expect(gate.claim('other', day()), true);
    },
  );
  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets(
      'daily completion uses server counts and offers both exits at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final c = ProviderContainer(
          overrides: [
            dashboardRepositoryProvider.overrideWithValue(
              FakeDashboardRepository(),
            ),
          ],
        );
        addTearDown(c.dispose);
        var finished = 0, more = 0;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              theme: buildAppTheme(),
              home: DailyGoalCompleteScreen(
                progress: UserProgress(
                  totalXp: 100,
                  level: 2,
                  currentStreak: 5,
                  longestStreak: 7,
                  today: day(),
                ),
                onFinish: () => finished++,
                onMore: () => more++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('5 gün'), findsOneWidget);
        expect(find.text('Rekor: 7'), findsOneWidget);
        expect(
          find.text(
            '10 soruyu yeniden çözdün. Yarın daha güçlü başlayacaksın.',
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Biraz daha tekrar et'));
        await tester.tap(find.text('Biraz daha tekrar et'));
        expect(more, 1);
        await tester.tap(find.text('Harika, bitir'));
        expect(finished, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
