import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

Dio createDio(AppConfig config) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response == null) {
            debugPrint('Hatora connection: ${error.type.name}; ${error.error}');
          }
          handler.next(error);
        },
      ),
    );
  }
  return dio;
}
