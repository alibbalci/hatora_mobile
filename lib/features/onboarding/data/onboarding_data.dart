import 'package:dio/dio.dart';

import '../../../core/error/failure_mapper.dart';
import '../domain/onboarding.dart';

class OnboardingDto {
  OnboardingDto.fromJson(Map<String, dynamic> json)
    : completed = json['onboardingCompleted'] as bool,
      dailyGoal = json['dailyReviewGoal'] as int,
      activeExam = json['activeExam'] as Map<String, dynamic>?;
  final bool completed;
  final int dailyGoal;
  final Map<String, dynamic>? activeExam;
}

OnboardingStatus mapOnboarding(OnboardingDto dto) {
  final exam = dto.activeExam;
  return OnboardingStatus(
    completed: dto.completed,
    dailyReviewGoal: dto.dailyGoal,
    examId: exam?['examId'] as String?,
    examEditionId: exam?['examEditionId'] as String?,
    examDisplay: exam == null ? null : '${exam['examName']} · ${exam['year']}',
    examDate: exam?['examDate'] == null
        ? null
        : DateTime.parse(exam!['examDate'] as String),
  );
}

class OnboardingRemoteDataSource {
  OnboardingRemoteDataSource(this.dio);
  final Dio dio;
  Future<OnboardingDto> status() async => OnboardingDto.fromJson(
    (await dio.get<Map<String, dynamic>>('/api/onboarding')).data!,
  );
  Future<OnboardingDto> complete(String editionId, int dailyGoal) async =>
      OnboardingDto.fromJson(
        (await dio.post<Map<String, dynamic>>(
          '/api/onboarding/complete',
          data: {'examEditionId': editionId, 'dailyReviewGoal': dailyGoal},
        )).data!,
      );
  Future<int> updateDailyReviewGoal(int dailyGoal) async =>
      ((await dio.put<Map<String, dynamic>>(
            '/api/users/me/preferences',
            data: {'dailyReviewGoal': dailyGoal},
          )).data!['dailyReviewGoal']
          as int);
}

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this.remote);
  final OnboardingRemoteDataSource remote;
  @override
  Future<OnboardingStatus> status() =>
      repositoryCall(() async => mapOnboarding(await remote.status()));
  @override
  Future<OnboardingStatus> complete(String editionId, int dailyGoal) =>
      repositoryCall(
        () async => mapOnboarding(await remote.complete(editionId, dailyGoal)),
      );
  @override
  Future<int> updateDailyReviewGoal(int dailyGoal) =>
      repositoryCall(() => remote.updateDailyReviewGoal(dailyGoal));
}
