import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/error/app_failure.dart';
import 'package:hatora_mobile/features/auth/domain/auth.dart';
import 'package:hatora_mobile/features/auth/presentation/auth_view_model.dart';
import 'package:hatora_mobile/features/question/domain/question.dart';
import 'package:hatora_mobile/features/question/presentation/question_capture_view_model.dart';

import 'support/fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeAuthRepository auth;
  late FakeQuestionRepository questions;
  late FakeOnboardingRepository onboarding;
  late FakePicker picker;
  setUp(() {
    auth = FakeAuthRepository();
    questions = FakeQuestionRepository();
    onboarding = FakeOnboardingRepository();
    picker = FakePicker();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        onboardingRepositoryProvider.overrideWithValue(onboarding),
        questionRepositoryProvider.overrideWithValue(questions),
        imagePickerProvider.overrideWithValue(picker),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    auth.events.close();
  });

  test(
    'onboarding selection, goal, and workflow steps preserve the draft',
    () async {
      final vm = container.read(onboardingViewModelProvider.notifier);
      await flush();
      vm.selectExam(choice);
      vm.setDailyGoal(20);
      vm.setStep(2);
      final state = container.read(onboardingViewModelProvider);
      expect(state.selectedExam?.editionId, 'edition');
      expect(state.dailyReviewGoal, 20);
      expect(state.currentStep, 2);
      await vm.complete(authenticated: false);
      expect(onboarding.completeCalls, 0);
      await vm.complete(authenticated: true);
      expect(onboarding.completeCalls, 1);
      expect(container.read(onboardingViewModelProvider).completed, true);
    },
  );
  test('auth invokes login use case and exposes loading and success', () async {
    final vm = container.read(authViewModelProvider.notifier);
    await flush();
    auth.pending = Completer<UserProfile>();
    final call = vm.submit(email: ' ada@example.com ', password: 'password');
    expect(container.read(authViewModelProvider).busy, true);
    expect(auth.loginCalls, 1);
    expect(auth.lastEmail, 'ada@example.com');
    auth.pending!.complete(user);
    await call;
    expect(
      container.read(authViewModelProvider).status,
      AuthStatus.authenticated,
    );
    expect(container.read(authViewModelProvider).busy, false);
  });
  test('auth failure is presentation-safe and register is distinct', () async {
    final vm = container.read(authViewModelProvider.notifier);
    await flush();
    auth.failure = const AppFailure(
      FailureKind.unauthorized,
      code: 'INVALID_CREDENTIALS',
    );
    await vm.submit(email: 'ada@example.com', password: 'password');
    expect(
      container.read(authViewModelProvider).failure?.message,
      'E-posta veya parola hatalı.',
    );
    auth.failure = null;
    await vm.submit(
      email: 'ada@example.com',
      password: 'password',
      displayName: 'Ada',
    );
    expect(auth.registerCalls, 1);
  });
  test('session invalidation clears the signed in user', () async {
    auth.session = user;
    container.read(authViewModelProvider);
    await flush();
    auth.events.add(null);
    await flush();
    expect(container.read(authViewModelProvider).status, AuthStatus.guest);
    expect(container.read(authViewModelProvider).user, null);
  });
  test('capture selection is explicit, cancellation preserves image, analysis succeeds', () async {
    container.listen(captureViewModelProvider, (_, _) {});
    final vm = container.read(captureViewModelProvider.notifier);
    await flush();
    await vm.selectImage(ImageOrigin.gallery);
    expect(
      container.read(captureViewModelProvider).phase,
      CapturePhase.imageSelected,
    );
    expect(container.read(captureViewModelProvider).analysis, null);
    picker.next = null;
    await vm.selectImage(ImageOrigin.camera);
    expect(container.read(captureViewModelProvider).image, same(selectedImage));
    await vm.analyze();
    expect(container.read(captureViewModelProvider).canContinue, true);
  });
  test('capture state is cleared once the capture screen is left', () async {
    final sub = container.listen(captureViewModelProvider, (_, _) {});
    final vm = container.read(captureViewModelProvider.notifier);
    await flush();
    await vm.selectImage(ImageOrigin.gallery);
    await vm.analyze();
    expect(container.read(captureViewModelProvider).canContinue, true);
    sub.close();
    await flush();
    container.listen(captureViewModelProvider, (_, _) {});
    final state = container.read(captureViewModelProvider);
    expect(state.image, null);
    expect(state.analysis, null);
  });
  test(
    'AI failure permits manual continuation with a real analysis id',
    () async {
      questions.nextAnalysis = QuestionAnalysis(
        id: 'failed-analysis',
        status: AnalysisStatus.failed,
        manualSelectionRequired: true,
        expiresAt: DateTime.utc(2030),
      );
      container.listen(captureViewModelProvider, (_, _) {});
      final vm = container.read(captureViewModelProvider.notifier);
      await flush();
      await vm.selectImage(ImageOrigin.gallery);
      await vm.analyze();
      final state = container.read(captureViewModelProvider);
      expect(state.phase, CapturePhase.analysisFailure);
      expect(state.canContinue, true);
      expect(state.seed?.analysis.id, 'failed-analysis');
    },
  );
  test(
    'upload failure requires retry and cannot invent manual analysis',
    () async {
      questions.analyzeFailure = const AppFailure(FailureKind.network);
      container.listen(captureViewModelProvider, (_, _) {});
      final vm = container.read(captureViewModelProvider.notifier);
      await flush();
      await vm.selectImage(ImageOrigin.gallery);
      await vm.analyze();
      expect(container.read(captureViewModelProvider).canContinue, false);
      expect(
        container.read(captureViewModelProvider).failure?.kind,
        FailureKind.network,
      );
      questions.analyzeFailure = null;
      await vm.analyze();
      expect(container.read(captureViewModelProvider).canContinue, true);
    },
  );
  test(
    'Android recovered image is selected without automatic upload',
    () async {
      picker.recovered = selectedImage;
      container.listen(captureViewModelProvider, (_, _) {});
      await flush();
      expect(
        container.read(captureViewModelProvider).phase,
        CapturePhase.imageSelected,
      );
    },
  );
  test('confirmation requires difficulty and explicit topic; AI does not choose for user', () async {
    final provider = confirmViewModelProvider(seed);
    container.listen(provider, (_, _) {});
    final vm = container.read(provider.notifier);
    await flush();
    expect(container.read(provider).topic, null);
    expect(vm.suggestedTopic?.id, topic.id);
    await vm.submit();
    expect(
      container.read(provider).fieldErrors,
      containsAll(['topicId', 'correctAnswer', 'mistakeReason', 'difficulty']),
    );
    vm.selectTopic(topic);
    vm.setAnswer('B');
    vm.setReason(MistakeReason.conceptGap);
    await vm.submit();
    expect(questions.createCalls, 0);
    expect(container.read(provider).fieldErrors, {'difficulty'});
    vm.setDifficulty(Difficulty.medium);
    await vm.submit();
    expect(container.read(provider).created?.id, 'question');
    expect(questions.lastDraft?.analysisId, 'analysis');
    expect(questions.lastDraft?.difficulty, Difficulty.medium);
    await vm.submit();
    expect(questions.createCalls, 1);
  });
  test('confirm rejects out-of-catalog answer, keeps draft on server failure, prevents double submit', () async {
    final provider = confirmViewModelProvider(seed);
    container.listen(provider, (_, _) {});
    final vm = container.read(provider.notifier);
    await flush();
    vm.selectTopic(topic);
    vm.setAnswer('E');
    vm.setReason(MistakeReason.misread);
    vm.setDifficulty(Difficulty.hard);
    await vm.submit();
    expect(container.read(provider).fieldErrors, {'correctAnswer'});
    vm.setAnswer('A');
    questions.createFailure = const AppFailure(FailureKind.network);
    await vm.submit();
    expect(container.read(provider).failure?.kind, FailureKind.network);
    expect(container.read(provider).topic, topic);
    questions.createFailure = null;
    questions.pendingCreate = Completer<Question>();
    final call = vm.submit();
    await vm.submit();
    expect(questions.createCalls, 2);
    questions.pendingCreate!.complete(question);
    await call;
    expect(container.read(provider).created, question);
  });
}
