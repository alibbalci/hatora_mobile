class OnboardingStatus {
  const OnboardingStatus({
    required this.completed,
    required this.dailyReviewGoal,
    this.examId,
    this.examEditionId,
    this.examDisplay,
    this.examDate,
  });
  final bool completed;
  final int dailyReviewGoal;
  final String? examId, examEditionId, examDisplay;
  final DateTime? examDate;
}

abstract interface class OnboardingRepository {
  Future<OnboardingStatus> status();
  Future<OnboardingStatus> complete(String editionId, int dailyGoal);
  Future<int> updateDailyReviewGoal(int dailyGoal);
}

class GetOnboardingStatusUseCase {
  const GetOnboardingStatusUseCase(this.repository);
  final OnboardingRepository repository;
  Future<OnboardingStatus> call() => repository.status();
}

class CompleteOnboardingUseCase {
  const CompleteOnboardingUseCase(this.repository);
  final OnboardingRepository repository;
  Future<OnboardingStatus> call(String editionId, int dailyGoal) =>
      repository.complete(editionId, dailyGoal);
}
