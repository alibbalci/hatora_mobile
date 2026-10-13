import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../domain/auth.dart';

enum AuthStatus { restoring, guest, authenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.restoring,
    this.user,
    this.busy = false,
    this.failure,
  });
  final AuthStatus status;
  final UserProfile? user;
  final bool busy;
  final AppFailure? failure;
}

class AuthViewModel extends Notifier<AuthState> {
  AuthViewModel(this.resolve);
  final ({
    LoginUseCase login,
    RegisterUseCase register,
    RestoreSessionUseCase restore,
    LogoutUseCase logout,
  })
  Function(Ref)
  resolve;
  LoginUseCase get login => resolve(ref).login;
  RegisterUseCase get register => resolve(ref).register;
  RestoreSessionUseCase get restoreSession => resolve(ref).restore;
  LogoutUseCase get logout => resolve(ref).logout;
  @override
  AuthState build() {
    final subscription = restoreSession.invalidated.listen((_) {
      if (ref.mounted) state = const AuthState(status: AuthStatus.guest);
    });
    ref.onDispose(subscription.cancel);
    Future.microtask(restore);
    return const AuthState();
  }

  Future<void> restore() async {
    if (state.busy) return;
    state = AuthState(status: state.status, user: state.user, busy: true);
    try {
      final user = await restoreSession();
      if (ref.mounted) {
        state = AuthState(
          status: user == null ? AuthStatus.guest : AuthStatus.authenticated,
          user: user,
        );
      }
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = AuthState(
          status: state.status,
          user: state.user,
          failure: failure,
        );
      }
    }
  }

  Future<void> submit({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (state.busy) return;
    final registering = displayName != null;
    if (registering && utf8.encode(password).length > 72) {
      state = const AuthState(
        status: AuthStatus.guest,
        failure: AppFailure(
          FailureKind.validation,
          code: 'PASSWORD_TOO_LONG',
          fields: ['password'],
        ),
      );
      return;
    }
    final invalid =
        email.trim().isEmpty ||
        !email.contains('@') ||
        password.isEmpty ||
        (registering &&
            (displayName.trim().isEmpty ||
                displayName.trim().length > 100 ||
                password.length < 8 ||
                password.length > 100 ||
                email.trim().length > 255));
    if (invalid) {
      state = const AuthState(
        status: AuthStatus.guest,
        failure: AppFailure(FailureKind.validation),
      );
      return;
    }
    state = const AuthState(status: AuthStatus.guest, busy: true);
    try {
      final user = registering
          ? await register(email, password, displayName)
          : await login(email, password);
      if (ref.mounted) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      }
    } on AppFailure catch (failure) {
      if (registering && failure.code == 'EMAIL_ALREADY_REGISTERED') {
        try {
          final user = await login(email, password);
          if (ref.mounted) {
            state = AuthState(status: AuthStatus.authenticated, user: user);
          }
          return;
        } on AppFailure catch (loginFailure) {
          if (ref.mounted) {
            state = AuthState(
              status: loginFailure.code == 'PROFILE_LOAD_FAILED_AFTER_AUTH'
                  ? AuthStatus.restoring
                  : AuthStatus.guest,
              failure: loginFailure,
            );
          }
          return;
        }
      }
      if (ref.mounted) {
        state = AuthState(
          status: failure.code == 'PROFILE_LOAD_FAILED_AFTER_AUTH'
              ? AuthStatus.restoring
              : AuthStatus.guest,
          failure: failure,
        );
      }
    }
  }

  Future<void> signOut() async {
    if (state.busy) return;
    final user = state.user;
    state = AuthState(status: state.status, user: user, busy: true);
    try {
      await logout();
      if (ref.mounted) state = const AuthState(status: AuthStatus.guest);
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          failure: failure,
        );
      }
    }
  }

  void synchronizeProfile(UserProfile user) {
    if (state.status == AuthStatus.authenticated && state.user?.id == user.id) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    }
  }
}
