class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.onboardingCompleted,
    this.email = '',
    this.authProvider = '',
    this.createdAt,
  });
  final String id, displayName;
  final bool onboardingCompleted;
  final String email, authProvider;
  final DateTime? createdAt;
}

abstract interface class AuthRepository {
  Future<UserProfile> login(String email, String password);
  Future<UserProfile> register(
    String email,
    String password,
    String displayName,
  );
  Future<UserProfile?> restore();
  Future<UserProfile> profile();
  Future<UserProfile> updateDisplayName(String displayName);
  Future<void> logout();
  Stream<void> get invalidated;
}

class LoginUseCase {
  const LoginUseCase(this.repository);
  final AuthRepository repository;
  Future<UserProfile> call(String email, String password) =>
      repository.login(email.trim(), password);
}

class RegisterUseCase {
  const RegisterUseCase(this.repository);
  final AuthRepository repository;
  Future<UserProfile> call(String email, String password, String name) =>
      repository.register(email.trim(), password, name.trim());
}

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this.repository);
  final AuthRepository repository;
  Future<UserProfile?> call() => repository.restore();
  Stream<void> get invalidated => repository.invalidated;
}

class LogoutUseCase {
  const LogoutUseCase(this.repository);
  final AuthRepository repository;
  Future<void> call() => repository.logout();
}
