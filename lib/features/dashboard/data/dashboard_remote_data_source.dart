import 'package:dio/dio.dart';

import 'dashboard_dto.dart';

class DashboardRemoteDataSource {
  const DashboardRemoteDataSource(this.dio);
  final Dio dio;
  Future<DashboardDto> get() async => DashboardDto.fromJson(
    (await dio.get<Map<String, dynamic>>('/api/dashboard')).data!,
  );
}
