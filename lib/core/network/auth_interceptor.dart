import 'package:dio/dio.dart';

import 'session_tokens.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.dio, this.tokens);
  final Dio dio;
  final SessionTokens tokens;
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (options.uri.origin != Uri.parse(dio.options.baseUrl).origin) {
        return handler.reject(
          DioException(requestOptions: options, error: 'Unexpected API origin'),
        );
      }
      if (options.extra['public'] != true) {
        if (options.extra['retried'] == true &&
            options.extra['generation'] != tokens.generation) {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
            ),
          );
        }
        final pair = await tokens.storage.read();
        options.extra['generation'] = tokens.generation;
        if (pair != null) {
          options.headers['Authorization'] = 'Bearer ${pair.accessToken}';
        }
      }
      handler.next(options);
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final error = err;
    final request = error.requestOptions;
    if (error.response?.statusCode == 401 &&
        request.extra['retried'] == true &&
        request.extra['generation'] == tokens.generation) {
      try {
        await tokens.clear();
      } catch (_) {
        /* Preserve the HTTP failure. */
      }
      return handler.next(error);
    }
    if (error.response?.statusCode != 401 ||
        request.extra['public'] == true ||
        request.extra['retried'] == true ||
        request.headers['Authorization'] == null ||
        request.extra['generation'] != tokens.generation) {
      return handler.next(error);
    }
    try {
      final current = await tokens.storage.read();
      if (current == null) return handler.next(error);
      final pair =
          request.headers['Authorization'] != 'Bearer ${current.accessToken}'
          ? current
          : await tokens.refresh();
      if (request.extra['generation'] != tokens.generation) {
        return handler.next(error);
      }
      final data = request.data;
      final retry = request.copyWith(
        data: data is FormData ? data.clone() : data,
        headers: {
          ...request.headers,
          'Authorization': 'Bearer ${pair.accessToken}',
        },
        extra: {...request.extra, 'retried': true},
      );
      handler.resolve(await dio.fetch<dynamic>(retry));
    } on DioException catch (refreshError) {
      handler.next(refreshError);
    } catch (_) {
      handler.next(error);
    }
  }
}
