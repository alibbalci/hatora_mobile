import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/error/app_failure.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/features/auth/data/auth_dto.dart';
import 'package:hatora_mobile/features/auth/domain/auth.dart';
import 'package:hatora_mobile/features/auth/presentation/auth_view_model.dart';
import 'package:hatora_mobile/features/profile/presentation/profile_screen.dart';
import 'package:hatora_mobile/features/profile/presentation/profile_view_model.dart';

import 'support/fakes.dart';

const profileUser = UserProfile(
  id: 'u',
  displayName: 'Muhammet Ali Balcı Çok Uzun Profil İsmi',
  onboardingCompleted: true,
  email: 'uzun.bir.eposta.adresi@example.com',
  authProvider: 'LOCAL',
);
ProviderContainer container(FakeAuthRepository auth) => ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(auth),
    onboardingRepositoryProvider.overrideWithValue(FakeOnboardingRepository()),
    progressRepositoryProvider.overrideWithValue(FakeProgressRepository()),
  ],
);
void main() {
  test('user profile DTO maps account fields and optional date', () {
    final user = mapProfile(
      UserProfileDto.fromJson({
        'id': 'u',
        'email': 'a@b.com',
        'displayName': 'Ada',
        'authProvider': 'LOCAL',
        'onboardingCompleted': true,
        'createdAt': '2026-09-13T10:00:00Z',
      }),
    );
    expect(user.email, 'a@b.com');
    expect(user.createdAt, DateTime.utc(2026, 9, 13, 10));
    final optional = mapProfile(
      UserProfileDto.fromJson({
        'id': 'u',
        'displayName': 'Ada',
        'onboardingCompleted': true,
      }),
    );
    expect(optional.email, '');
    expect(optional.createdAt, isNull);
  });
  test('profile loads composed real sources and refreshes', () async {
    final auth = FakeAuthRepository()..session = profileUser;
    final c = container(auth);
    addTearDown(() {
      c.dispose();
      auth.events.close();
    });
    c.read(profileViewModelProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final s = c.read(profileViewModelProvider);
    expect(s.phase, ProfilePhase.ready);
    expect(s.overview?.user.email, profileUser.email);
    expect(s.overview?.study.dailyReviewGoal, 10);
    expect(s.overview?.progress.totalXp, 120);
    await c.read(profileViewModelProvider.notifier).refresh();
    expect(auth.profileCalls, 2);
  });
  test('temporary profile failure shows error and does not clear authenticated session', () async {
    final auth = FakeAuthRepository()
      ..session = profileUser
      ..failure = const AppFailure(FailureKind.network);
    final c = container(auth);
    addTearDown(() {
      c.dispose();
      auth.events.close();
    });
    c.read(authViewModelProvider);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(authViewModelProvider).status, AuthStatus.authenticated);
    c.read(profileViewModelProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(profileViewModelProvider).phase, ProfilePhase.error);
    expect(auth.session, profileUser);
    expect(c.read(authViewModelProvider).status, AuthStatus.authenticated);
  });
  testWidgets(
    'profile renders identity initials exam goal and backend progress without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = FakeAuthRepository()..session = profileUser;
      final c = container(auth);
      addTearDown(() {
        c.dispose();
        auth.events.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: ProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MA'), findsOneWidget);
      expect(find.text(profileUser.email), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('120 XP'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('120 XP'), findsOneWidget);
      expect(find.text('Seviye 2'), findsOneWidget);
      expect(find.text('4 gün'), findsOneWidget);
      expect(find.text('En uzun: 8 gün'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Aktif sınav'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Aktif sınav'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Günlük tekrar hedefi'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('10 soru'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('logout requires confirmation and reuses auth session flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = FakeAuthRepository()..session = profileUser;
    final c = container(auth);
    addTearDown(() {
      c.dispose();
      auth.events.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: buildAppTheme(), home: const ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Çıkış Yap'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Çıkış Yap').first);
    await tester.pumpAndSettle();
    expect(find.text('Çıkış yapılsın mı?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Çıkış Yap'),
      ),
    );
    await tester.pumpAndSettle();
    expect(auth.session, isNull);
    expect(c.read(authViewModelProvider).status, AuthStatus.guest);
  });
}
