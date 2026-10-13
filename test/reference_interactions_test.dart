import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/core/widget/reference_widgets.dart';
import 'package:hatora_mobile/features/export/domain/export_models.dart';
import 'package:hatora_mobile/features/export/presentation/export_screen.dart';

import 'support/fakes.dart';

import 'package:hatora_mobile/features/question/presentation/my_questions_screens.dart';

import 'package:hatora_mobile/features/question/presentation/question_screens.dart';

class CountedExports extends FakeExportRepository {
  @override
  Future<ExportOptions> options() async => const ExportOptions(3, [
    ExportSubjectCount('math', 'Matematik', 3),
    ExportSubjectCount('history', 'Tarih', 0),
  ]);
}

void main() {
  testWidgets(
    'edit counts changed fields and undo restores form text and answer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          onboardingRepositoryProvider.overrideWithValue(
            FakeOnboardingRepository(),
          ),
          questionRepositoryProvider.overrideWithValue(
            FakeQuestionRepository(),
          ),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const QuestionEditScreen(id: 'question'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 değişiklik'), findsOneWidget);
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(find.text('1 değişiklik'), findsOneWidget);
      final note = find.byKey(const ValueKey('note-0'));
      await tester.ensureVisible(note);
      await tester.enterText(note, 'Yeni not');
      await tester.pumpAndSettle();
      expect(find.text('2 değişiklik'), findsOneWidget);
      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(find.text('0 değişiklik'), findsOneWidget);
      expect(find.text('Yeni not'), findsNothing);
      expect(c.read(questionEditViewModelProvider('question')).answer, 'B');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'confirmation requires four user selections and opens full photo',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          onboardingRepositoryProvider.overrideWithValue(
            FakeOnboardingRepository(),
          ),
          questionRepositoryProvider.overrideWithValue(
            FakeQuestionRepository(),
          ),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: QuestionConfirmScreen(seed: seed),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 / 4 tamam'), findsOneWidget);
      await tester.tap(find.text('Tam ekran'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Onayla'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Kavram eksikliği'));
      await tester.tap(find.text('Kavram eksikliği'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Orta'));
      await tester.tap(find.text('Orta'));
      await tester.pumpAndSettle();
      expect(find.text('4 / 4 tamam'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final action in ['Kaydet', 'Vazgeç']) {
    testWidgets('input remains alive while dialog closes: $action', (
      tester,
    ) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (_) => const ReferenceInputDialog(
                      title: 'Hedef',
                      initialValue: '10',
                      numeric: true,
                    ),
                  );
                },
                child: const Text('Aç'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '15');
      await tester.tap(find.text(action));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(result, action == 'Kaydet' ? '15' : null);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('PDF uses account counts and disables empty subjects', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [exportRepositoryProvider.overrideWithValue(CountedExports())],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: SingleChildScrollView(child: ExportSheetBody()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 soruyu PDF yap'), findsOneWidget);
    await tester.tap(find.text('Tarih'));
    await tester.pumpAndSettle();
    expect(container.read(exportViewModelProvider).subjectId, isNull);
    await tester.tap(find.text('Matematik'));
    await tester.pumpAndSettle();
    expect(container.read(exportViewModelProvider).subjectId, 'math');
    expect(find.text('3 soruyu PDF yap'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
