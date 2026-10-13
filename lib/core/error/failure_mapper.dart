import 'dart:convert';

import 'package:dio/dio.dart';

import 'app_failure.dart';

AppFailure mapFailure(Object error) {
  if (error is AppFailure) return error;
  if (error is! DioException) return const AppFailure(FailureKind.unknown);
  final response = error.response;
  if (response == null) return const AppFailure(FailureKind.network);
  var body = response.data;
  if (body is List<int>) {
    try {
      body = jsonDecode(utf8.decode(body));
    } on FormatException {
      body = null;
    }
  }
  final code = body is Map && body['code'] is String
      ? body['code'] as String
      : null;
  final seconds = int.tryParse(response.headers.value('retry-after') ?? '');
  final retryAfter = seconds != null && seconds >= 0
      ? Duration(seconds: seconds)
      : null;
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
  return AppFailure(
    kind,
    code: code,
    fields: List.unmodifiable(fields),
    retryAfter: retryAfter,
  );
}

Future<T> repositoryCall<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (error) {
    throw mapFailure(error);
  }
}
