import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/features/question/domain/question.dart';
import 'package:hatora_mobile/features/question/presentation/question_capture_view_model.dart';
import 'package:hatora_mobile/features/question/presentation/question_analysis_screen.dart';

import 'support/fakes.dart';

class PendingAnalysis extends FakeQuestionRepository {
  final pending = Completer<QuestionAnalysis>();
  @override
  Future<QuestionAnalysis> analyze(SelectedImage image) => pending.future;
}

void main() {
  test('estimated route never completes without a response', () {
    expect(
      estimatedAnalysisProgress(const Duration(seconds: 2)),
      closeTo(.3, .001),
    );
    expect(
      estimatedAnalysisProgress(const Duration(seconds: 4)),
      closeTo(.62, .001),
    );
    expect(estimatedAnalysisProgress(const Duration(minutes: 5)), .9);
  });
  test('cancelled analysis ignores a late response', () async {
    final repo = PendingAnalysis();
    final c = ProviderContainer(
      overrides: [
        questionRepositoryProvider.overrideWithValue(repo),
        imagePickerProvider.overrideWithValue(FakePicker()),
      ],
    );
    addTearDown(c.dispose);
    c.listen(captureViewModelProvider, (_, _) {});
    final vm = c.read(captureViewModelProvider.notifier);
    await vm.selectImage(ImageOrigin.gallery);
    final pending = vm.analyze();
    vm.cancelAnalysis();
    repo.pending.complete(analysis);
    await pending;
    expect(c.read(captureViewModelProvider).phase, CapturePhase.imageSelected);
    expect(c.read(captureViewModelProvider).analysis, isNull);
  });
  testWidgets(
    'long wait stays incomplete; only actual response completes steps',
    (tester) async {
      final c = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          onboardingRepositoryProvider.overrideWithValue(
            FakeOnboardingRepository(),
          ),
        ],
      );
      addTearDown(c.dispose);
      Widget screen(CaptureState state) => UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: QuestionAnalysisScreen(
            state: state,
            onCancel: () {},
            onRetry: () {},
            onNewImage: () {},
            onContinue: () {},
          ),
        ),
      );
      await tester.pumpWidget(
        screen(
          CaptureState(phase: CapturePhase.analyzing, image: selectedImage),
        ),
      );
      await tester.pump(const Duration(seconds: 16));
      expect(find.text('Biraz uzun sürüyor, bekliyoruz…'), findsOneWidget);
      expect(find.text('Buldum'), findsNothing);
      expect(find.text('Vazgeç'), findsOneWidget);
      await tester.pumpWidget(
        screen(
          CaptureState(
            phase: CapturePhase.analysisSuccess,
            image: selectedImage,
            analysis: analysis,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Buldum'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('early response completes quickly', (tester) async {
    final c = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        onboardingRepositoryProvider.overrideWithValue(
          FakeOnboardingRepository(),
        ),
      ],
    );
    addTearDown(c.dispose);
    Widget screen(CaptureState state) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: buildAppTheme(),
        home: QuestionAnalysisScreen(
          state: state,
          onCancel: () {},
          onRetry: () {},
          onNewImage: () {},
          onContinue: () {},
        ),
      ),
    );
    await tester.pumpWidget(
      screen(CaptureState(phase: CapturePhase.analyzing, image: selectedImage)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(
      screen(
        CaptureState(
          phase: CapturePhase.analysisSuccess,
          image: selectedImage,
          analysis: analysis,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Buldum'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
