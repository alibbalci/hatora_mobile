import 'progress_models.dart';
import 'progress_repository.dart';

class GetProgressUseCase {
  const GetProgressUseCase(this.repository);
  final ProgressRepository repository;
  Future<UserProgress> call() => repository.getProgress();
}
