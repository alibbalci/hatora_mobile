import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/core/error/app_failure.dart';
import 'package:hatora_mobile/core/network/session_tokens.dart';
import 'package:hatora_mobile/core/storage/token_storage.dart';
import 'package:hatora_mobile/features/auth/data/auth_dto.dart';
import 'package:hatora_mobile/features/auth/data/auth_remote_data_source.dart';
import 'package:hatora_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:hatora_mobile/features/auth/domain/auth.dart';
import 'package:hatora_mobile/features/auth/presentation/auth_view_model.dart';
import 'package:hatora_mobile/features/question/domain/question.dart';
import 'package:hatora_mobile/features/review/data/review_dto.dart';
import 'package:hatora_mobile/features/review/data/review_mapper.dart';
import 'package:hatora_mobile/features/review/data/review_remote_data_source.dart';
import 'package:hatora_mobile/features/review/domain/review_models.dart';
import 'package:hatora_mobile/features/review/domain/review_repository.dart';
import 'package:hatora_mobile/features/review/domain/review_use_cases.dart';
import 'package:hatora_mobile/features/review/presentation/review_session_view_model.dart';
import 'package:hatora_mobile/features/review/presentation/review_states.dart';

import 'support/fakes.dart';

void main() {
  test(
    'auth keeps a recoverable session when profile fails after login',
    () async {
      final storage = MemoryTokenStorage();
      final tokens = SessionTokens(
        storage,
        (_) async => const TokenPair('a2', 'r2'),
      );
      final repository = AuthRepositoryImpl(
        _ProfileFailingAuthRemote(),
        tokens,
      );

      await expectLater(
        repository.login('a@b.com', 'password'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.code,
            'code',
            'PROFILE_LOAD_FAILED_AFTER_AUTH',
          ),
        ),
      );
      expect((await storage.read())?.accessToken, 'access');
      tokens.dispose();
    },
  );

  test(
    'auth ViewModel exposes profile failure as restoring, not guest',
    () async {
      final repository = _ProfileUnavailableRepository();
      final provider = NotifierProvider<AuthViewModel, AuthState>(
        () => AuthViewModel(
          (_) => (
            login: LoginUseCase(repository),
            register: RegisterUseCase(repository),
            restore: RestoreSessionUseCase(repository),
            logout: LogoutUseCase(repository),
          ),
        ),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(provider);
      await Future<void>.delayed(Duration.zero);
      await container
          .read(provider.notifier)
          .submit(email: 'a@b.com', password: 'password');
      expect(container.read(provider).status, AuthStatus.restoring);
    },
  );

  test(
    'registration conflict recovers by logging in with the same credentials',
    () async {
      final repository = _ExistingAccountRepository();
      final provider = NotifierProvider<AuthViewModel, AuthState>(
        () => AuthViewModel(
          (_) => (
            login: LoginUseCase(repository),
            register: RegisterUseCase(repository),
            restore: RestoreSessionUseCase(repository),
            logout: LogoutUseCase(repository),
          ),
        ),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(provider);
      await Future<void>.delayed(Duration.zero);
      await container
          .read(provider.notifier)
          .submit(email: 'a@b.com', password: 'password', displayName: 'Ada');
      expect(repository.registerCalls, 1);
      expect(repository.loginCalls, 1);
      expect(container.read(provider).status, AuthStatus.authenticated);
    },
  );

  test('review DTOs map all backend-owned result fields', () {
    final result = mapAnswerResult(AnswerResultDto.fromJson(_answerJson));
    expect(result.result, ReviewResult.wrong);
    expect(result.correctAnswer, 'B');
    expect(result.newStage, 0);
    expect(result.nextReviewDate, DateTime(2026, 9, 14));
    expect(result.mastered, false);
    expect(result.solutionImages.single.sortOrder, 0);
  });

  test('unknown review enum fails in a controlled way', () {
    final json = Map<String, dynamic>.from(_answerJson)..['result'] = 'MAYBE';
    expect(
      () => mapAnswerResult(AnswerResultDto.fromJson(json)),
      throwsA(isA<FormatException>()),
    );
  });

  test('next-item 204 maps to no next item', () async {
    final dio = Dio()..httpClientAdapter = _NoContentAdapter();
    final remote = ReviewRemoteDataSource(dio);
    expect(await remote.nextItem('session'), isNull);
  });

  test(
    'session ViewModel submits selected answer and renders backend truth',
    () async {
      final repository = _FakeReviewRepository();
      final context = const ReviewSessionContext('session', 4);
      final provider =
          NotifierProvider<ReviewSessionViewModel, ReviewSessionState>(
            () => ReviewSessionViewModel(
              context,
              (_) => (
                next: GetNextReviewItemUseCase(repository),
                submit: SubmitReviewAnswerUseCase(repository),
              ),
            ),
          );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(provider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(provider).phase, ReviewSessionPhase.ready);
      expect(container.read(provider).result, isNull);

      container.read(provider.notifier).selectAnswer('A');
      await container.read(provider.notifier).submit();
      expect(repository.lastAnswer, 'A');
      expect(container.read(provider).result?.result, ReviewResult.wrong);
      expect(container.read(provider).result?.correctAnswer, 'B');
    },
  );

  test('session ViewModel sends an unambiguous unsolved intent', () async {
    final repository = _FakeReviewRepository();
    final provider =
        NotifierProvider<ReviewSessionViewModel, ReviewSessionState>(
          () => ReviewSessionViewModel(
            const ReviewSessionContext('session', 4),
            (_) => (
              next: GetNextReviewItemUseCase(repository),
              submit: SubmitReviewAnswerUseCase(repository),
            ),
          ),
        );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(provider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    container.read(provider.notifier).selectUnsolved();
    await container.read(provider.notifier).submit();
    expect(repository.lastAnswer, isNull);
    expect(repository.lastUnsolved, true);
  });
}

class _ProfileFailingAuthRemote extends AuthRemoteDataSource {
  _ProfileFailingAuthRemote() : super(Dio());
  @override
  Future<TokenDto> login(String email, String password) async =>
      TokenDto.fromJson({'accessToken': 'access', 'refreshToken': 'refresh'});
  @override
  Future<UserProfileDto> profile() => throw DioException(
    requestOptions: RequestOptions(path: '/api/users/me'),
    type: DioExceptionType.connectionError,
  );
}

class _ProfileUnavailableRepository implements AuthRepository {
  final _invalidated = StreamController<void>.broadcast();
  @override
  Stream<void> get invalidated => _invalidated.stream;
  @override
  Future<UserProfile> login(String email, String password) =>
      throw const AppFailure(
        FailureKind.network,
        code: 'PROFILE_LOAD_FAILED_AFTER_AUTH',
      );
  @override
  Future<UserProfile> register(
    String email,
    String password,
    String displayName,
  ) => login(email, password);
  @override
  Future<UserProfile?> restore() async => null;
  @override
  Future<void> logout() async {}
  @override
  Future<UserProfile> profile() => login('', '');
  @override
  Future<UserProfile> updateDisplayName(String displayName) => login('', '');
}

class _ExistingAccountRepository implements AuthRepository {
  int registerCalls = 0, loginCalls = 0;
  @override
  Stream<void> get invalidated => const Stream.empty();
  @override
  Future<UserProfile> register(
    String email,
    String password,
    String displayName,
  ) async {
    registerCalls++;
    throw const AppFailure(
      FailureKind.conflict,
      code: 'EMAIL_ALREADY_REGISTERED',
    );
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    loginCalls++;
    return const UserProfile(
      id: 'user',
      displayName: 'Ada',
      onboardingCompleted: false,
    );
  }

  @override
  Future<UserProfile?> restore() async => null;
  @override
  Future<void> logout() async {}
  @override
  Future<UserProfile> profile() async => login('', '');
  @override
  Future<UserProfile> updateDisplayName(String displayName) async =>
      login('', '');
}

class _NoContentAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromBytes([], 204);
  @override
  void close({bool force = false}) {}
}

class _FakeReviewRepository implements ReviewRepository {
  String? lastAnswer;
  bool? lastUnsolved;
  @override
  Future<NextReviewItem?> getNextItem(String sessionId) async => NextReviewItem(
    itemId: 'item',
    questionId: 'question',
    position: 0,
    totalItems: 1,
    topicId: 'topic',
    topicName: 'Konu',
    subjectId: 'subject',
    subjectName: 'Ders',
    examCode: 'LGS',
    imageUri: Uri.parse('/api/files/q'),
    difficulty: Difficulty.medium,
  );
  @override
  Future<ReviewImage> loadImage(Uri uri) async =>
      ReviewImage(Uint8List(0), null);
  @override
  Future<AnswerResult> submitAnswer(
    String itemId, {
    String? selectedAnswer,
    required bool unsolved,
  }) async {
    lastAnswer = selectedAnswer;
    lastUnsolved = unsolved;
    return mapAnswerResult(AnswerResultDto.fromJson(_answerJson));
  }

  @override
  Future<ReviewSession> createOrResume({String? subjectId, String? topicId}) =>
      throw UnimplementedError();
  @override
  Future<List<DueCountItem>> getDueCounts({String? subjectId}) =>
      throw UnimplementedError();
  @override
  Future<ReviewSession> getSession(String id) => throw UnimplementedError();
  @override
  Future<List<ReviewSession>> getSessions({ReviewSessionStatus? status}) =>
      throw UnimplementedError();
  @override
  Future<ReviewSetupData> getSetup() => throw UnimplementedError();
}

final _answerJson = <String, dynamic>{
  'itemId': 'item',
  'questionId': 'question',
  'skipped': false,
  'skipReason': null,
  'result': 'WRONG',
  'selectedAnswer': 'A',
  'correctAnswer': 'B',
  'previousStage': 1,
  'newStage': 0,
  'nextReviewDate': '2026-09-14',
  'questionStatus': 'ACTIVE',
  'mastered': false,
  'shortNote': 'Not',
  'mistakeReason': 'MISREAD',
  'solutionImages': [
    {'id': 'solution', 'imageAccessUri': '/api/files/s', 'sortOrder': 0},
  ],
  'imageAccessUri': '/api/files/q',
  'sessionCompleted': false,
};
