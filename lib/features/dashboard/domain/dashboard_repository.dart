import 'dashboard_models.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> getDashboard();
}
