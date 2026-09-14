import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../domain/review_models.dart';
import 'review_dto.dart';

class ReviewRemoteDataSource {
  ReviewRemoteDataSource(this.dio);
  final Dio dio;

  Future<DueSummaryDto> dueSummary() async => DueSummaryDto.fromJson(
    (await dio.get<Map<String, dynamic>>('/api/reviews/due-summary')).data!,
  );

  Future<DueCountsDto> dueCounts({String? subjectId}) async =>
      DueCountsDto.fromJson(
        (await dio.get<Map<String, dynamic>>(
          '/api/reviews/due-counts',
          queryParameters: subjectId == null ? null : {'subjectId': subjectId},
        )).data!,
      );

  Future<ReviewSessionDto> createOrResume({
    String? subjectId,
    String? topicId,
  }) async => ReviewSessionDto.fromJson(
    (await dio.post<Map<String, dynamic>>(
      '/api/review-sessions',
      data: {'subjectId': subjectId, 'topicId': topicId},
    )).data!,
  );

  Future<List<ReviewSessionDto>> sessions({String? status}) async {
    final response = await dio.get<List<dynamic>>(
      '/api/review-sessions',
      queryParameters: status == null ? null : {'status': status},
    );
    return response.data!
        .map((e) => ReviewSessionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewSessionDto> session(String id) async =>
      ReviewSessionDto.fromJson(
        (await dio.get<Map<String, dynamic>>('/api/review-sessions/$id')).data!,
      );

  Future<NextReviewItemDto?> nextItem(String sessionId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/review-sessions/$sessionId/next-item',
      options: Options(
        validateStatus: (status) => status == 200 || status == 204,
      ),
    );
    return response.statusCode == 204
        ? null
        : NextReviewItemDto.fromJson(response.data!);
  }

  Future<AnswerResultDto> submitAnswer(
    String itemId, {
    String? selectedAnswer,
    required bool unsolved,
  }) async => AnswerResultDto.fromJson(
    (await dio.post<Map<String, dynamic>>(
      '/api/reviews/session-items/$itemId/answer',
      data: {'selectedAnswer': selectedAnswer, 'unsolved': unsolved},
    )).data!,
  );

  Future<ReviewImage> image(Uri uri) async {
    final response = await dio.get<List<int>>(
      uri.toString(),
      options: Options(responseType: ResponseType.bytes),
    );
    return ReviewImage(
      Uint8List.fromList(response.data!),
      response.headers.value(Headers.contentTypeHeader),
    );
  }
}
