import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/app.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/app/router.dart';
import 'package:hatora_mobile/app/routes.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/core/widget/components.dart';
import 'package:hatora_mobile/features/auth/domain/auth.dart';
import 'package:hatora_mobile/features/onboarding/presentation/onboarding_screens.dart';
import 'package:hatora_mobile/features/question/presentation/question_screens.dart';

import 'support/fakes.dart';

void main() {
  ProviderContainer setup({bool signedIn = false}) {
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
      ],
    );
    addTearDown(() {
      container.dispose();
      auth.events.close();
    });
    return container;
  }

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    testWidgets('onboarding route and selection survive navigation at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = setup();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HatoraApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Hadi başlayalım'));
      await tester.tap(find.text('Hadi başlayalım'));
      await tester.pumpAndSettle();
      expect(find.text('Hangi sınava\nhazırlanıyorsun?'), findsOneWidget);
      await tester.tap(find.text('Test sınavı 2026'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Devam et'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Devam et'));
      await tester.pumpAndSettle();
      expect(find.text('Küçük adımlar,\nkalıcı öğrenme.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('20'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      container.read(routerProvider).pop();
      await tester.pumpAndSettle();
      expect(container.read(onboardingViewModelProvider).dailyReviewGoal, 20);
      expect(
        container.read(onboardingViewModelProvider).selectedExam?.editionId,
        'edition',
      );
      container.read(routerProvider).go(Routes.value);
      await tester.pumpAndSettle();
      expect(find.text('20 soru'), findsOneWidget);
      await tester.tap(find.text('E-postayla hesap oluştur'));
      await tester.pumpAndSettle();
      expect(find.text('Hesabını oluştur'), findsOneWidget);
      expect(container.read(onboardingViewModelProvider).dailyReviewGoal, 20);
      expect(
        container.read(onboardingViewModelProvider).selectedExam?.editionId,
        'edition',
      );
      expect(tester.takeException(), null);
    });
    testWidgets('capture and confirmation shell with large text at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = setup(signedIn: true);
      Widget screen(Widget child) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child,
          ),
        ),
      );
      await tester.pumpWidget(screen(const QuestionCaptureScreen()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Galeri'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Galeri'), findsOneWidget);
      await tester.tap(find.text('Galeri'));
      await tester.pumpAndSettle();
      expect(find.byType(QuestionImageCard), findsOneWidget);
      await tester.pumpWidget(screen(QuestionConfirmScreen(seed: seed)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Zorluk'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Zorluk'), findsOneWidget);
      expect(tester.takeException(), null);
    });
  }
  testWidgets('answer bubbles render catalog count and emit selection', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerOptions(
            count: 4,
            selected: null,
            onSelected: (s) => chosen = s,
          ),
        ),
      ),
    );
    expect(find.text('D'), findsOneWidget);
    expect(find.text('E'), findsNothing);
    await tester.tap(find.text('B'));
    expect(chosen, 'B');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerOptions(count: 5, selected: chosen, onSelected: (_) {}),
        ),
      ),
    );
    expect(find.text('E'), findsOneWidget);
  });
  testWidgets(
    'authenticated router opens home and redirects malformed confirm link',
    (tester) async {
      final container = setup(signedIn: true);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HatoraApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Merhaba, Ada'), findsOneWidget);
      container.read(routerProvider).go(Routes.confirm);
      await tester.pumpAndSettle();
      expect(find.text('Yanlış ekle'), findsOneWidget);
      expect(tester.takeException(), null);
    },
  );
  testWidgets('authenticated onboarding draft completes automatically', (
    tester,
  ) async {
    const incompleteUser = UserProfile(
      id: 'user',
      displayName: 'Ada',
      onboardingCompleted: false,
    );
    final auth = FakeAuthRepository()..session = incompleteUser;
    final onboarding = FakeOnboardingRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        onboardingRepositoryProvider.overrideWithValue(onboarding),
      ],
    );
    addTearDown(() {
      container.dispose();
      auth.events.close();
    });
    container.read(onboardingViewModelProvider.notifier).selectExam(choice);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ValuePropositionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(onboarding.completeCalls, 1);
    expect(container.read(onboardingViewModelProvider).completed, true);
  });
}
