import 'package:dio/dio.dart';

import 'catalog_dto.dart';

class CatalogRemoteDataSource {
  CatalogRemoteDataSource(this.dio);
  final Dio dio;
  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final response = await dio.get<List<dynamic>>(
      path,
      options: Options(extra: {'public': true}),
    );
    return response.data!.map((e) => parse(e as Map<String, dynamic>)).toList();
  }

  Future<List<ExamDto>> exams() =>
      _list('/api/catalog/exams', ExamDto.fromJson);
  Future<List<EditionDto>> editions(String examId) =>
      _list('/api/catalog/exams/$examId/editions', EditionDto.fromJson);
  Future<List<CatalogNodeDto>> sections(String examId) =>
      _list('/api/catalog/exams/$examId/sections', CatalogNodeDto.fromJson);
  Future<List<CatalogNodeDto>> subjects(String sectionId) => _list(
    '/api/catalog/sections/$sectionId/subjects',
    CatalogNodeDto.fromJson,
  );
  Future<List<CatalogNodeDto>> topics(String subjectId) =>
      _list('/api/catalog/subjects/$subjectId/topics', CatalogNodeDto.fromJson);
}
