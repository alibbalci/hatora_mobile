import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../catalog/domain/catalog.dart';
import '../domain/onboarding.dart';

class OnboardingState {
  const OnboardingState({
    this.choices = const AsyncLoading(),
    this.selectedExam,
    this.dailyReviewGoal = 10,
    this.currentStep = 0,
    this.busy = false,
    this.failure,
    this.completed = false,
  });
  final AsyncValue<List<ExamChoice>> choices;
  final ExamChoice? selectedExam;
  final int dailyReviewGoal, currentStep;
  final bool busy, completed;
  final AppFailure? failure;
  OnboardingState copyWith({
    AsyncValue<List<ExamChoice>>? choices,
    ExamChoice? selectedExam,
    int? dailyReviewGoal,
    int? currentStep,
    bool? busy,
    AppFailure? failure,
    bool? completed,
  }) => OnboardingState(
    choices: choices ?? this.choices,
    selectedExam: selectedExam ?? this.selectedExam,
    dailyReviewGoal: dailyReviewGoal ?? this.dailyReviewGoal,
    currentStep: currentStep ?? this.currentStep,
    busy: busy ?? this.busy,
    failure: failure,
    completed: completed ?? this.completed,
  );
}

class OnboardingViewModel extends Notifier<OnboardingState> {
  OnboardingViewModel(this.resolve);
  final ({LoadExamChoicesUseCase load, CompleteOnboardingUseCase complete})
  Function(Ref)
  resolve;
  LoadExamChoicesUseCase get loadChoices => resolve(ref).load;
  CompleteOnboardingUseCase get completeOnboarding => resolve(ref).complete;
  @override
  OnboardingState build() {
    Future.microtask(load);
    return const OnboardingState();
  }

  Future<void> load() async {
    state = state.copyWith(choices: const AsyncLoading());
    final choices = await AsyncValue.guard(loadChoices.call);
    if (ref.mounted) state = state.copyWith(choices: choices);
  }

  void selectExam(ExamChoice exam) =>
      state = state.copyWith(selectedExam: exam);
  void setDailyGoal(int goal) {
    if (goal >= 1 && goal <= 200) state = state.copyWith(dailyReviewGoal: goal);
  }

  void setStep(int step) => state = state.copyWith(currentStep: step);
  Future<void> complete({required bool authenticated}) async {
    if (state.busy) return;
    if (!authenticated || state.selectedExam == null) {
      state = state.copyWith(failure: const AppFailure(FailureKind.validation));
      return;
    }
    state = state.copyWith(busy: true);
    try {
      final result = await completeOnboarding(
        state.selectedExam!.editionId,
        state.dailyReviewGoal,
      );
      if (ref.mounted) {
        state = state.copyWith(busy: false, completed: result.completed);
      }
    } on AppFailure catch (failure) {
      if (ref.mounted) state = state.copyWith(busy: false, failure: failure);
    }
  }
}
