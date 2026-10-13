import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/core/widget/startup_animation.dart';
import 'package:hatora_mobile/features/home/presentation/home_screen.dart';
import 'package:hatora_mobile/features/dashboard/domain/dashboard_models.dart';

import 'support/fakes.dart';

class WaitingDashboard extends FakeDashboardRepository {
  final pending = Completer<DashboardSummary>();
  @override
  Future<DashboardSummary> getDashboard() => pending.future;
}

void main() {
  testWidgets(
    'startup finishes once and keeps logo visible while session waits',
    (tester) async {
      var finished = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HatoraStartupAnimation(onFinished: () => finished++),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));
      expect(finished, 0);
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();
      expect(finished, 1);
      await tester.pump(const Duration(seconds: 4));
      expect(finished, 1);
      expect(find.text('Hatalarını rotaya dönüştür'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('home shows skeleton until real dashboard arrives', (
    tester,
  ) async {
    final repo = WaitingDashboard(),
        auth = FakeAuthRepository()..session = user;
    final c = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWithValue(auth),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      ],
    );
    addTearDown(() {
      c.dispose();
      auth.events.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: buildAppTheme(), home: const HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(HomeLoadingSkeleton), findsOneWidget);
    expect(find.text('Merhaba, Ada'), findsNothing);
    repo.pending.complete(dashboardSummary);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(HomeLoadingSkeleton), findsNothing);
    expect(find.text('Merhaba, Ada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
