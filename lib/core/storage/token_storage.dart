import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenPair {
  const TokenPair(this.accessToken, this.refreshToken);
  final String accessToken;
  final String refreshToken;
}

abstract interface class TokenStorage {
  Future<TokenPair?> read();
  Future<void> write(TokenPair tokens);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this.storage);
  final FlutterSecureStorage storage;
  static const key = 'hatora.session.v1';
  @override
  Future<TokenPair?> read() async {
    final raw = await storage.read(key: key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TokenPair(
        json['accessToken'] as String,
        json['refreshToken'] as String,
      );
    } on Object {
      await clear();
      return null;
    }
  }

  // TR: Tek güvenli kayıt, yarım token çiftinin kalmasını önler.
  // EN: A single secure record avoids persisting half a rotated pair.
  @override
  Future<void> write(TokenPair tokens) => storage.write(
    key: key,
    value: jsonEncode({
      'accessToken': tokens.accessToken,
      'refreshToken': tokens.refreshToken,
    }),
  );
  @override
  Future<void> clear() => storage.delete(key: key);
}
