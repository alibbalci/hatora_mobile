import 'package:dio/dio.dart';

import 'app_failure.dart';

AppFailure mapFailure(Object error) {
  if (error is AppFailure) return error;
  if (error is! DioException) return const AppFailure(FailureKind.unknown);
  final response = error.response;
  if (response == null) return const AppFailure(FailureKind.network);
  final body = response.data;
  final code = body is Map ? body['code'] as String? : null;
  final details = body is Map ? body['details'] : null;
  final fieldErrors = details is Map ? details['fieldErrors'] : null;
  final fields = fieldErrors is List
      ? fieldErrors
            .whereType<Map>()
            .map((e) => e['field'])
            .whereType<String>()
            .toList()
      : <String>[];
  final kind = switch (response.statusCode) {
    401 => FailureKind.unauthorized,
    400 || 413 || 415 => FailureKind.validation,
    404 || 410 => FailureKind.notFound,
    409 => FailureKind.conflict,
    403 || 422 || 429 => FailureKind.businessRule,
    final int status when status >= 500 => FailureKind.server,
    _ => FailureKind.unknown,
  };
  // TR: Ham mesaj ve reddedilen değerler UI'ya taşınmaz.
  // EN: Raw messages and rejected values never reach presentation.
  return AppFailure(kind, code: code, fields: List.unmodifiable(fields));
}

Future<T> repositoryCall<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (error) {
    throw mapFailure(error);
  }
}
