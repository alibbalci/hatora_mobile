import 'package:dio/dio.dart';

import 'progress_dto.dart';

class ProgressRemoteDataSource {
  const ProgressRemoteDataSource(this.dio);
  final Dio dio;
  Future<UserProgressDto> getProgress() async => UserProgressDto.fromJson(
    (await dio.get<Map<String, dynamic>>('/api/users/me/progress')).data!,
  );
}
