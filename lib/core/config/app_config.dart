import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({String? apiBaseUrl})
    : _configuredUrl =
          apiBaseUrl ?? const String.fromEnvironment('API_BASE_URL');
  final String _configuredUrl;

  String get apiBaseUrl {
    final configured = _configuredUrl.trim();
    final value = configured.isNotEmpty
        ? configured
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8080'
        : 'http://127.0.0.1:8080';
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError('API_BASE_URL must be a valid HTTP(S) server URL.');
    }
    if (kReleaseMode && uri.scheme != 'https') {
      throw StateError('Release builds require an HTTPS API_BASE_URL.');
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
