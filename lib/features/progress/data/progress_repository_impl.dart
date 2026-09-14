import '../../../core/error/failure_mapper.dart';
import '../domain/progress_models.dart';
import '../domain/progress_repository.dart';
import 'progress_mapper.dart';
import 'progress_remote_data_source.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  const ProgressRepositoryImpl(this.remote);
  final ProgressRemoteDataSource remote;
  @override
  Future<UserProgress> getProgress() =>
      repositoryCall(() async => mapUserProgress(await remote.getProgress()));
}
