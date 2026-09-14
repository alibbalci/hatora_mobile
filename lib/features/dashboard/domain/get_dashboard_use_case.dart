import 'dashboard_models.dart';
import 'dashboard_repository.dart';

class GetDashboardUseCase {
  const GetDashboardUseCase(this.repository);
  final DashboardRepository repository;
  Future<DashboardSummary> call() => repository.getDashboard();
}
