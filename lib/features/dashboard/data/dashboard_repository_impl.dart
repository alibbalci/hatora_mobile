import '../../../core/error/failure_mapper.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_mapper.dart';
import 'dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this.remote);
  final DashboardRemoteDataSource remote;
  @override
  Future<DashboardSummary> getDashboard() =>
      repositoryCall(() async => mapDashboard(await remote.get()));
}
