import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hatora_mobile/core/config/app_config.dart';
import 'package:hatora_mobile/core/network/api_client.dart';
import 'package:hatora_mobile/core/network/auth_interceptor.dart';
import 'package:hatora_mobile/core/network/session_tokens.dart';
import 'package:hatora_mobile/core/storage/token_storage.dart';
import 'package:hatora_mobile/features/question/data/question_remote_data_source.dart';

import 'support/fakes.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions request) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) await requestStream.drain<void>();
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody body(int status, [Map<String, dynamic> data = const {}]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'secure storage atomically round trips and removes both tokens',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = SecureTokenStorage(const FlutterSecureStorage());
      expect(await storage.read(), null);
      await storage.write(const TokenPair('access', 'refresh'));
      expect((await storage.read())?.refreshToken, 'refresh');
      await storage.write(const TokenPair('next-access', 'next-refresh'));
      expect((await storage.read())?.accessToken, 'next-access');
      await storage.clear();
      expect(await storage.read(), null);
    },
  );
  test(
    'concurrent and late 401s share one rotation and use new token',
    () async {
      final storage = MemoryTokenStorage()
        ..pair = const TokenPair('old', 'refresh');
      var rotations = 0;
      final tokens = SessionTokens(storage, (refresh) async {
        rotations++;
        expect(refresh, 'refresh');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const TokenPair('new', 'rotated');
      });
      final dio = createDio(const AppConfig());
      dio.interceptors.add(AuthInterceptor(dio, tokens));
      dio.httpClientAdapter = FakeAdapter((request) async {
        if (request.headers['Authorization'] == 'Bearer old') {
          if (request.path == '/slow') {
            await Future<void>.delayed(const Duration(milliseconds: 30));
          }
          return body(401);
        }
        expect(request.headers['Authorization'], 'Bearer new');
        return body(200);
      });
      await Future.wait([
        dio.get<dynamic>('/one'),
        dio.get<dynamic>('/two'),
        dio.get<dynamic>('/slow'),
      ]);
      expect(rotations, 1);
      expect(storage.pair?.refreshToken, 'rotated');
      dio.close();
      tokens.dispose();
    },
  );
  test(
    'auth/public 401 never refreshes and never sends bearer credentials',
    () async {
      final storage = MemoryTokenStorage()..pair = const TokenPair('a', 'r');
      var rotations = 0;
      final tokens = SessionTokens(storage, (_) async {
        rotations++;
        return const TokenPair('x', 'y');
      });
      final dio = createDio(const AppConfig())..interceptors.addAll([]);
      dio.interceptors.add(AuthInterceptor(dio, tokens));
      dio.httpClientAdapter = FakeAdapter((request) async {
        expect(request.headers['Authorization'], null);
        return body(401);
      });
      await expectLater(
        dio.post<dynamic>(
          '/api/auth/login',
          options: Options(extra: {'public': true}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(rotations, 0);
      dio.close();
      tokens.dispose();
    },
  );
  test(
    'terminal refresh failure clears credentials and emits invalidation once',
    () async {
      final storage = MemoryTokenStorage()..pair = const TokenPair('a', 'r');
      final tokens = SessionTokens(storage, (_) async {
        final request = RequestOptions(path: '/api/auth/refresh');
        throw DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: 401),
        );
      });
      final event = tokens.invalidated.first;
      await expectLater(tokens.refresh(), throwsA(isA<DioException>()));
      await event;
      expect(storage.pair, null);
      tokens.dispose();
    },
  );
  test('offline refresh preserves persisted credentials', () async {
    final storage = MemoryTokenStorage()..pair = const TokenPair('a', 'r');
    final tokens = SessionTokens(
      storage,
      (_) async => throw DioException(
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
        type: DioExceptionType.connectionTimeout,
      ),
    );
    await expectLater(tokens.refresh(), throwsA(isA<DioException>()));
    expect(storage.pair?.refreshToken, 'r');
    tokens.dispose();
  });
  test(
    'retry is bounded and rejected refreshed access invalidates the session',
    () async {
      final storage = MemoryTokenStorage()..pair = const TokenPair('old', 'r');
      var rotations = 0, requests = 0;
      final tokens = SessionTokens(storage, (_) async {
        rotations++;
        return const TokenPair('new', 'r2');
      });
      final dio = createDio(const AppConfig());
      dio.interceptors.add(AuthInterceptor(dio, tokens));
      dio.httpClientAdapter = FakeAdapter((_) async {
        requests++;
        return body(401);
      });
      await expectLater(
        dio.get<dynamic>('/protected'),
        throwsA(isA<DioException>()),
      );
      expect(rotations, 1);
      expect(requests, 2);
      expect(storage.pair, null);
      dio.close();
      tokens.dispose();
    },
  );
  test(
    'multipart analysis uses file field and cloned body on auth retry',
    () async {
      final storage = MemoryTokenStorage()..pair = const TokenPair('old', 'r');
      final tokens = SessionTokens(
        storage,
        (_) async => const TokenPair('new', 'r2'),
      );
      final dio = createDio(const AppConfig());
      dio.interceptors.add(AuthInterceptor(dio, tokens));
      var requests = 0;
      dio.httpClientAdapter = FakeAdapter((request) async {
        requests++;
        expect(request.path, '/api/question-analyses');
        final form = request.data as FormData;
        expect(form.files.single.key, 'file');
        expect(form.files.single.value.contentType.toString(), 'image/png');
        if (requests == 1) return body(401);
        return body(201, {
          'id': 'a',
          'status': 'FAILED',
          'manualSelectionRequired': true,
          'expiresAt': '2030-01-01T00:00:00Z',
        });
      });
      final result = await QuestionRemoteDataSource(dio).analyze(selectedImage);
      expect(result.id, 'a');
      expect(requests, 2);
      dio.close();
      tokens.dispose();
    },
  );
  test(
    'API interceptor refuses sending tokens to a different origin',
    () async {
      final storage = MemoryTokenStorage()
        ..pair = const TokenPair('secret', 'refresh');
      final tokens = SessionTokens(
        storage,
        (_) async => const TokenPair('a', 'b'),
      );
      final dio = createDio(const AppConfig());
      dio.interceptors.add(AuthInterceptor(dio, tokens));
      var requests = 0;
      dio.httpClientAdapter = FakeAdapter((_) async {
        requests++;
        return body(200);
      });
      await expectLater(
        dio.get<dynamic>('https://unrelated.example/file'),
        throwsA(isA<DioException>()),
      );
      expect(requests, 0);
      dio.close();
      tokens.dispose();
    },
  );
}
