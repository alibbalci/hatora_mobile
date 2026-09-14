import 'package:dio/dio.dart';

import '../config/app_config.dart';

Dio createDio(AppConfig config) => Dio(
  BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Accept': 'application/json'},
  ),
);
