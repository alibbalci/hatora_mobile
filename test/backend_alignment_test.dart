import 'dart:async';
import 'package:hatora_mobile/features/catalog/domain/catalog.dart';
import 'package:hatora_mobile/features/question/domain/question_use_cases.dart';
import 'support/fakes.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/core/error/failure_mapper.dart';
import 'package:hatora_mobile/core/network/session_tokens.dart';
import 'package:hatora_mobile/core/storage/token_storage.dart';
import 'package:hatora_mobile/core/time/calendar_date.dart';
import 'package:hatora_mobile/features/catalog/data/catalog_dto.dart';
import 'package:hatora_mobile/features/export/domain/export_models.dart';

class DelayedStorage implements TokenStorage {
  TokenPair? pair = const TokenPair('old', 'refresh');
  final clearing = Completer<void>();
  bool started = false;
  @override
  Future<TokenPair?> read() async => pair;
  @override
  Future<void> write(TokenPair value) async {
    pair = value;
  }

  @override
  Future<void> clear() async {
    started = true;
    await clearing.future;
    pair = null;
  }
}

class TrackingCatalog extends FakeCatalogRepository {
  String? requestedExam;
  @override
  Future<QuestionCatalog> questionCatalog(String examId) {
    requestedExam = examId;
    return super.questionCatalog(examId);
  }
}

void main() {
  test('past editions hidden while current day and unannounced future remain', () {
    final now = DateTime(2026, 10, 12);
    expect(isPastExam(DateTime(2026, 10, 11), 2026, now: now), isTrue);
    expect(isPastExam(DateTime(2026, 10, 12), 2026, now: now), isFalse);
    expect(isPastExam(null, 2025, now: now), isTrue);
    expect(isPastExam(null, 2027, now: now), isFalse);
  });
  test('estimated month is explicitly unofficial and official date wins', () {
    final estimate = estimateExamMonth(2027, [DateTime(2025, 5, 10), DateTime(2026, 6, 20)]);
    expect(examDateLabel(null, estimatedDate: estimate), 'Yaklaşık Haziran 2027 · Resmî tarih açıklanmadı');
    expect(examDateLabel(DateTime(2027, 6, 19), estimatedDate: estimate), '19.6.2027');
  });

  test('editing an old question uses its exam instead of active exam', () async {
    final catalog = TrackingCatalog();
    await LoadQuestionCatalogUseCase(FakeOnboardingRepository(), catalog)(examId: 'old-exam');
    expect(catalog.requestedExam, 'old-exam');
  });

  test('new login survives an earlier slow storage deletion', () async {
    final storage = DelayedStorage();
    final tokens = SessionTokens(
      storage,
      (_) async => const TokenPair('rotated', 'r'),
    );
    final clear = tokens.clear();
    await Future<void>.delayed(Duration.zero);
    expect(storage.started, isTrue);
    final save = tokens.save(const TokenPair('new', 'new-refresh'));
    storage.clearing.complete();
    await Future.wait([clear, save]);
    expect(storage.pair?.accessToken, 'new');
    tokens.dispose();
  });
  test('late authentication failure cannot clear a newer login', () async {
    final storage = DelayedStorage();
    final tokens = SessionTokens(
      storage,
      (_) async => const TokenPair('rotated', 'r'),
    );
    final oldGeneration = tokens.generation;
    await tokens.save(const TokenPair('new', 'new-refresh'));
    await tokens.clear(expectedGeneration: oldGeneration);
    expect(storage.started, isFalse);
    expect(storage.pair?.accessToken, 'new');
    tokens.dispose();
  });
  test('binary download errors preserve code and retry delay', () {
    final request = RequestOptions(path: '/download');
    final failure = mapFailure(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['12'],
          }),
          data: utf8.encode(
            jsonEncode({'code': 'RATE_LIMITED', 'message': 'private'}),
          ),
        ),
      ),
    );
    expect(failure.code, 'RATE_LIMITED');
    expect(failure.retryAfter, const Duration(seconds: 12));
  });
  test(
    'invalid binary server response is handled without parsing exception',
    () {
      final request = RequestOptions(path: '/download');
      expect(
        mapFailure(
          DioException(
            requestOptions: request,
            response: Response(
              requestOptions: request,
              statusCode: 500,
              data: [255],
            ),
          ),
        ).code,
        isNull,
      );
    },
  );
  test('unannounced exam date stays nullable', () {
    final session = ExamSessionDto.fromJson({
      'code': 'TYT',
      'name': 'TYT',
      'examDate': null,
      'sourceUrl': null,
    });
    expect(session.examDate, isNull);
    expect(calendarDateLabel(null), 'Tarih henüz açıklanmadı');
  });
  test('past exam date is identified without claiming today', () {
    expect(
      calendarDateLabel(DateTime(2026, 6, 20), now: DateTime(2026, 10, 12)),
      '20.6.2026 · Sınav yapıldı',
    );
  });
  test('export expires precisely at the declared boundary', () {
    final expiration = DateTime.utc(2026, 10, 12);
    final job = ExportJob(
      id: 'j',
      status: ExportJobStatus.completed,
      createdAt: expiration,
      expiresAt: expiration,
    );
    expect(
      job.expiredAt(expiration.subtract(const Duration(seconds: 1))),
      isFalse,
    );
    expect(job.expiredAt(expiration), isTrue);
  });
}
