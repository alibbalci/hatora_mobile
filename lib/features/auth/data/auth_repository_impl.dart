import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../../../core/network/session_tokens.dart';
import '../domain/auth.dart';
import 'auth_dto.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.remote, this.tokens);
  final AuthRemoteDataSource remote;
  final SessionTokens tokens;
  @override
  Stream<void> get invalidated => tokens.invalidated;
  @override
  Future<UserProfile> login(String email, String password) =>
      repositoryCall(() async {
        await tokens.save(mapTokens(await remote.login(email, password)));
        return _profileAfterAuthentication();
      });
  @override
  Future<UserProfile> register(
    String email,
    String password,
    String displayName,
  ) => repositoryCall(() async {
    await tokens.save(
      mapTokens(await remote.register(email, password, displayName)),
    );
    return _profileAfterAuthentication();
  });

  Future<UserProfile> _profileAfterAuthentication() async {
    try {
      return mapProfile(await remote.profile());
    } catch (error) {
      final failure = mapFailure(error);
      if (failure.kind == FailureKind.unauthorized) {
        await tokens.clear();
        throw failure;
      }
      throw AppFailure(failure.kind, code: 'PROFILE_LOAD_FAILED_AFTER_AUTH');
    }
  }

  @override
  Future<UserProfile?> restore() => repositoryCall(() async {
    if (await tokens.storage.read() == null) return null;
    try {
      return mapProfile(await remote.profile());
    } catch (error) {
      if (mapFailure(error).kind == FailureKind.unauthorized) {
        await tokens.clear();
        return null;
      }
      rethrow;
    }
  });
  @override
  Future<UserProfile> profile() =>
      repositoryCall(() async => mapProfile(await remote.profile()));
  @override
  Future<UserProfile> updateDisplayName(String displayName) => repositoryCall(
    () async => mapProfile(await remote.updateDisplayName(displayName.trim())),
  );
  @override
  Future<void> logout() => repositoryCall(() async {
    await tokens.settle();
    final pair = await tokens.storage.read();
    // TR: Ağ hatasında oturum korunur; kullanıcı güvenle yeniden deneyebilir.
    // EN: Keep the session on a network error so revocation can be retried.
    if (pair != null) await remote.logout(pair.refreshToken);
    await tokens.clear();
  });
}
