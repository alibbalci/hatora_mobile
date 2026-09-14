import 'package:dio/dio.dart';

import 'dart:typed_data';

import '../domain/question.dart';
import 'question_dto.dart';
import 'question_mapper.dart';

class QuestionRemoteDataSource {
  QuestionRemoteDataSource(this.dio);
  final Dio dio;
  Future<QuestionAnalysisDto> analyze(SelectedImage image) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        image.bytes,
        filename: image.name,
        contentType: DioMediaType.parse(image.mimeType),
      ),
    });
    return QuestionAnalysisDto.fromJson(
      (await dio.post<Map<String, dynamic>>(
        '/api/question-analyses',
        data: form,
      )).data!,
    );
  }

  Future<QuestionDto> create(QuestionDraft draft) async => QuestionDto.fromJson(
    (await dio.post<Map<String, dynamic>>(
      '/api/questions',
      data: mapQuestionRequest(draft),
    )).data!,
  );

  Future<QuestionPageDto> getQuestions({
    required int page,
    required int size,
    required QuestionFilters filters,
  }) async {
    final query = <String, dynamic>{'page': page, 'size': size};
    if (filters.status != null && filters.status != QuestionStatus.unknown) {
      query['status'] = filters.status!.name.toUpperCase();
    }
    if (filters.subjectId != null) query['subjectId'] = filters.subjectId;
    if (filters.topicId != null) query['topicId'] = filters.topicId;
    if (filters.difficulty != null) {
      query['difficulty'] = difficultyWire[filters.difficulty];
    }
    if (filters.mistakeReason != null) {
      query['mistakeReason'] = mistakeReasonWire[filters.mistakeReason];
    }
    return QuestionPageDto.fromJson(
      (await dio.get<Map<String, dynamic>>(
        '/api/questions',
        queryParameters: query,
      )).data!,
    );
  }

  Future<QuestionDto> getQuestion(String id) async => QuestionDto.fromJson(
    (await dio.get<Map<String, dynamic>>('/api/questions/$id')).data!,
  );

  Future<QuestionDto> updateQuestion(String id, QuestionUpdate update) async =>
      QuestionDto.fromJson(
        (await dio.patch<Map<String, dynamic>>(
          '/api/questions/$id',
          data: mapQuestionUpdate(update),
        )).data!,
      );

  Future<void> archiveQuestion(String id) async =>
      dio.delete<void>('/api/questions/$id');

  Future<QuestionImage> image(Uri uri) async {
    final response = await dio.get<List<int>>(
      uri.toString(),
      options: Options(responseType: ResponseType.bytes),
    );
    return QuestionImage(
      Uint8List.fromList(response.data!),
      response.headers.value(Headers.contentTypeHeader),
    );
  }
}
