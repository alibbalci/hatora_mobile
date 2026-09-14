import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../domain/profile_models.dart';
import '../domain/profile_use_cases.dart';

enum ProfilePhase { loading, ready, refreshing, saving, error }

class ProfileState {
  const ProfileState({
    this.phase = ProfilePhase.loading,
    this.overview,
    this.failure,
  });
  final ProfilePhase phase;
  final ProfileOverview? overview;
  final AppFailure? failure;
}

class ProfileViewModel extends Notifier<ProfileState> {
  ProfileViewModel(this.resolve);
  final ({
    GetProfileOverviewUseCase get,
    UpdateProfileNameUseCase updateName,
    UpdateDailyGoalUseCase updateGoal,
  })
  Function(Ref)
  resolve;
  @override
  ProfileState build() {
    Future.microtask(load);
    return const ProfileState();
  }

  Future<void> load() async {
    final old = state.overview;
    state = ProfileState(
      phase: old == null ? ProfilePhase.loading : ProfilePhase.refreshing,
      overview: old,
    );
    try {
      final value = await resolve(ref).get();
      if (ref.mounted) {
        state = ProfileState(phase: ProfilePhase.ready, overview: value);
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = ProfileState(
          phase: ProfilePhase.error,
          overview: old,
          failure: e,
        );
      }
    }
  }

  Future<void> refresh() => load();
  Future<void> retry() => load();
  Future<bool> updateName(String name) async {
    final value = name.trim();
    if (value.isEmpty || value.length > 100) {
      state = ProfileState(
        phase: ProfilePhase.ready,
        overview: state.overview,
        failure: const AppFailure(FailureKind.validation),
      );
      return false;
    }
    return _save(() => resolve(ref).updateName(value));
  }

  Future<bool> updateGoal(int goal) async {
    if (goal < 1 || goal > 200) {
      state = ProfileState(
        phase: ProfilePhase.ready,
        overview: state.overview,
        failure: const AppFailure(FailureKind.validation),
      );
      return false;
    }
    return _save(() => resolve(ref).updateGoal(goal));
  }

  Future<bool> _save(Future<Object> Function() action) async {
    final old = state.overview;
    state = ProfileState(phase: ProfilePhase.saving, overview: old);
    try {
      await action();
      final value = await resolve(ref).get();
      if (ref.mounted) {
        state = ProfileState(phase: ProfilePhase.ready, overview: value);
      }
      return true;
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = ProfileState(
          phase: ProfilePhase.ready,
          overview: old,
          failure: e,
        );
      }
      return false;
    }
  }
}
