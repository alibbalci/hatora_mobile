import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../domain/export_models.dart';
import 'export_dto.dart';

class ExportRemoteDataSource {
  const ExportRemoteDataSource(this.dio);
  final Dio dio;

  Future<ExportJobDto> create({String? subjectId, String? topicId}) async =>
      ExportJobDto.fromJson(
        (await dio.post<Map<String, dynamic>>(
          '/api/exports',
          data: {'format': 'PDF', 'subjectId': subjectId, 'topicId': topicId},
        )).data!,
      );

  Future<ExportJobDto> get(String id) async => ExportJobDto.fromJson(
    (await dio.get<Map<String, dynamic>>('/api/exports/$id')).data!,
  );

  Future<ExportFile> download(String id) async {
    final response = await dio.get<List<int>>(
      '/api/exports/$id/download',
      options: Options(responseType: ResponseType.bytes),
    );
    return ExportFile(
      Uint8List.fromList(response.data!),
      response.headers.value(Headers.contentTypeHeader),
    );
  }
}
