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
  Future<void> _mutations = Future<void>.value();
  bool _disposed = false;
  int generation = 0;

  Future<void> _serialize(Future<void> Function() action) {
    final task = _mutations.then((_) async {
      if (_disposed) throw StateError('Session owner was disposed');
      await action();
    });
    // A failed secure-storage operation must not poison later transitions.
    _mutations = task.catchError((Object _) {});
    return task;
  }

  Future<void> save(TokenPair pair) async {
    await settle();
    await _serialize(() async {
      generation++;
      await storage.write(pair);
    });
  }

  Future<void> settle() async {
    try {
      await _refreshing;
    } catch (_) {
      // The refresh caller handles its failure.
    }
  }

  Future<void> clear({int? expectedGeneration}) async {
    await settle();
    await _serialize(() async {
      if (expectedGeneration != null && expectedGeneration != generation) {
        return;
      }
      generation++;
      await storage.clear();
      _invalidated.add(null);
    });
  }

  Future<TokenPair> refresh() {
    if (_disposed) {
      return Future.error(StateError('Session owner was disposed'));
    }
    final current = _refreshing;
    if (current != null) return current;
    final flight = _rotate();
    _refreshing = flight;
    return flight.whenComplete(() {
      _refreshing = null;
    });
  }

  Future<TokenPair> _rotate() async {
    final epoch = generation;
    final old = await storage.read();
    if (old == null || _disposed || epoch != generation) {
      throw StateError('Session changed');
    }
    try {
      final next = await rotate(old.refreshToken);
      await _serialize(() async {
        if (epoch != generation) throw StateError('Session changed');
        await storage.write(next);
      });
      return next;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _serialize(() async {
          if (epoch != generation) return;
          generation++;
          await storage.clear();
          _invalidated.add(null);
        });
      }
      rethrow;
    }
  }

  void dispose() {
    _disposed = true;
    _invalidated.close();
  }
}
