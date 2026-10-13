import '../../auth/domain/auth.dart';
import '../../onboarding/domain/onboarding.dart';
import '../../progress/domain/progress_repository.dart';
import '../../progress/domain/progress_models.dart';
import 'profile_models.dart';

class GetProfileOverviewUseCase {
  const GetProfileOverviewUseCase(this.auth, this.onboarding, this.progress);
  final AuthRepository auth;
  final OnboardingRepository onboarding;
  final ProgressRepository progress;
  Future<ProfileOverview> call() async {
    final values = await Future.wait<Object>([
      auth.profile(),
      onboarding.status(),
      progress.getProgress(),
    ]);
    return ProfileOverview(
      user: values[0] as UserProfile,
      study: values[1] as OnboardingStatus,
      progress: values[2] as UserProgress,
    );
  }
}

class UpdateProfileNameUseCase {
  const UpdateProfileNameUseCase(this.repository);
  final AuthRepository repository;
  Future<UserProfile> call(String name) => repository.updateDisplayName(name);
}

class UpdateDailyGoalUseCase {
  const UpdateDailyGoalUseCase(this.repository);
  final OnboardingRepository repository;
  Future<int> call(int goal) => repository.updateDailyReviewGoal(goal);
}

class SwitchProfileExamUseCase {
  const SwitchProfileExamUseCase(this.repository);
  final OnboardingRepository repository;
  Future<OnboardingStatus> call(String editionId) =>
      repository.activateExam(editionId);
}
