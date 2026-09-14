import 'progress_models.dart';

abstract interface class ProgressRepository {
  Future<UserProgress> getProgress();
}
