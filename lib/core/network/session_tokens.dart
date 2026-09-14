import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class SessionTokens {
  SessionTokens(this.storage, this.rotate);
  final TokenStorage storage;
  final Future<TokenPair> Function(String refreshToken) rotate;
  final _invalidated = StreamController<void>.broadcast();
  Stream<void> get invalidated => _invalidated.stream;
  Future<TokenPair>? _refreshing;
  int generation = 0;

  Future<void> save(TokenPair pair) async {
    await settle();
    generation++;
    await storage.write(pair);
  }

  Future<void> settle() async {
    try {
      await _refreshing;
    } catch (_) {
      /* Original caller handles failure. */
    }
  }

  Future<void> clear() async {
    await settle();
    generation++;
    await storage.clear();
    _invalidated.add(null);
  }

  // TR: Dönen refresh token tekrar kullanılamaz; istekler aynı işi bekler.
  // EN: Rotated refresh tokens cannot be reused; callers share one flight.
  Future<TokenPair> refresh() {
    final current = _refreshing;
    if (current != null) return current;
    final flight = _rotate();
    _refreshing = flight;
    return flight.whenComplete(() {
      _refreshing = null;
    });
  }

  Future<TokenPair> _rotate() async {
    final old = await storage.read();
    if (old == null) throw StateError('No session');
    try {
      final next = await rotate(old.refreshToken);
      await storage.write(next);
      return next;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        generation++;
        await storage.clear();
        _invalidated.add(null);
      }
      rethrow;
    }
  }

  void dispose() => _invalidated.close();
}
