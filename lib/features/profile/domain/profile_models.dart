import '../../auth/domain/auth.dart';
import '../../onboarding/domain/onboarding.dart';
import '../../progress/domain/progress_models.dart';

class ProfileOverview {
  const ProfileOverview({
    required this.user,
    required this.study,
    required this.progress,
  });
  final UserProfile user;
  final OnboardingStatus study;
  final UserProgress progress;
}
