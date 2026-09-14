import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/network/auth_interceptor.dart';
import '../core/network/session_tokens.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/data/auth_dto.dart';
import '../features/auth/data/auth_remote_data_source.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth.dart';
import '../features/auth/presentation/auth_view_model.dart';
import '../features/catalog/data/catalog_remote_data_source.dart';
import '../features/catalog/data/catalog_repository_impl.dart';
import '../features/catalog/domain/catalog.dart';
import '../features/catalog/presentation/topic_picker_view_model.dart';
import '../features/dashboard/data/dashboard_remote_data_source.dart';
import '../features/dashboard/data/dashboard_repository_impl.dart';
import '../features/dashboard/domain/dashboard_repository.dart';
import '../features/dashboard/domain/get_dashboard_use_case.dart';
import '../features/dashboard/presentation/dashboard_view_model.dart';
import '../features/export/data/export_remote_data_source.dart';
import '../features/export/data/export_repository_impl.dart';
import '../features/export/data/platform_export_file_opener.dart';
import '../features/export/domain/export_models.dart';
import '../features/export/domain/export_repository.dart';
import '../features/export/domain/export_use_cases.dart';
import '../features/export/presentation/export_view_model.dart';
import '../features/onboarding/data/onboarding_data.dart';
import '../features/onboarding/domain/onboarding.dart';
import '../features/onboarding/presentation/onboarding_view_model.dart';
import '../features/question/data/platform_image_picker.dart';
import '../features/question/data/question_remote_data_source.dart';
import '../features/question/data/question_repository_impl.dart';
import '../features/question/domain/question.dart';
import '../features/question/domain/question_use_cases.dart';
import '../features/question/presentation/question_capture_view_model.dart';
import '../features/question/presentation/question_confirm_view_model.dart';
import '../features/question/presentation/my_questions_view_model.dart';
import '../features/question/presentation/question_detail_view_model.dart';
import '../features/question/presentation/question_edit_view_model.dart';
import '../features/review/data/review_remote_data_source.dart';
import '../features/review/data/review_repository_impl.dart';
import '../features/review/domain/review_models.dart';
import '../features/review/domain/review_repository.dart';
import '../features/review/domain/review_use_cases.dart';
import '../features/review/presentation/review_session_view_model.dart';
import '../features/review/presentation/review_setup_view_model.dart';
import '../features/review/presentation/review_states.dart';
import '../features/progress/data/progress_remote_data_source.dart';
import '../features/progress/data/progress_repository_impl.dart';
import '../features/progress/domain/progress_repository.dart';
import '../features/progress/domain/get_progress_use_case.dart';
import '../features/progress/presentation/progress_view_model.dart';
import '../features/profile/domain/profile_use_cases.dart';
import '../features/profile/presentation/profile_view_model.dart';
import '../features/statistics/data/statistics_remote_data_source.dart';
import '../features/statistics/data/statistics_repository_impl.dart';
import '../features/statistics/domain/get_statistics_use_case.dart';
import '../features/statistics/domain/statistics_repository.dart';
import '../features/statistics/presentation/statistics_view_model.dart';

// TR: Somut sınıflar yalnızca bu bileşim noktasında bağlanır.
// EN: Concrete implementations are wired only at this composition root.
final appConfigProvider = Provider((ref) => const AppConfig());
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(const FlutterSecureStorage()),
);
final sessionTokensProvider = Provider((ref) {
  final refreshDio = createDio(ref.watch(appConfigProvider));
  final remote = AuthRemoteDataSource(refreshDio);
  final tokens = SessionTokens(
    ref.watch(tokenStorageProvider),
    (token) async => mapTokens(await remote.refresh(token)),
  );
  ref.onDispose(() {
    tokens.dispose();
    refreshDio.close();
  });
  return tokens;
});
final dioProvider = Provider<Dio>((ref) {
  final dio = createDio(ref.watch(appConfigProvider));
  dio.interceptors.add(AuthInterceptor(dio, ref.watch(sessionTokensProvider)));
  ref.onDispose(dio.close);
  return dio;
});
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(dioProvider)),
    ref.watch(sessionTokensProvider),
  ),
);
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) =>
      CatalogRepositoryImpl(CatalogRemoteDataSource(ref.watch(dioProvider))),
);
final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepositoryImpl(
    OnboardingRemoteDataSource(ref.watch(dioProvider)),
  ),
);
final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) =>
      QuestionRepositoryImpl(QuestionRemoteDataSource(ref.watch(dioProvider))),
);
final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepositoryImpl(ReviewRemoteDataSource(ref.watch(dioProvider))),
);
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) =>
      ProgressRepositoryImpl(ProgressRemoteDataSource(ref.watch(dioProvider))),
);
final statisticsRepositoryProvider = Provider<StatisticsRepository>(
  (ref) => StatisticsRepositoryImpl(
    StatisticsRemoteDataSource(ref.watch(dioProvider)),
  ),
);
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(
    DashboardRemoteDataSource(ref.watch(dioProvider)),
  ),
);
final exportRepositoryProvider = Provider<ExportRepository>(
  (ref) => ExportRepositoryImpl(ExportRemoteDataSource(ref.watch(dioProvider))),
);
final exportFileOpenerProvider = Provider<ExportFileOpener>(
  (ref) => const PlatformExportFileOpener(),
);
final imagePickerProvider = Provider<ImagePickerService>(
  (ref) => PlatformImagePicker(ImagePicker()),
);

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  () => AuthViewModel((ref) {
    final repository = ref.read(authRepositoryProvider);
    return (
      login: LoginUseCase(repository),
      register: RegisterUseCase(repository),
      restore: RestoreSessionUseCase(repository),
      logout: LogoutUseCase(repository),
    );
  }),
);
final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      () => OnboardingViewModel(
        (ref) => (
          load: LoadExamChoicesUseCase(ref.read(catalogRepositoryProvider)),
          complete: CompleteOnboardingUseCase(
            ref.read(onboardingRepositoryProvider),
          ),
        ),
      ),
    );
final dashboardViewModelProvider =
    NotifierProvider<DashboardViewModel, DashboardState>(
      () => DashboardViewModel(
        (ref) => (
          load: GetDashboardUseCase(ref.read(dashboardRepositoryProvider)),
          answerOptions: GetReviewAnswerOptionsUseCase(
            ref.read(onboardingRepositoryProvider),
            ref.read(catalogRepositoryProvider),
          ),
        ),
      ),
    );
final statisticsViewModelProvider =
    NotifierProvider<StatisticsViewModel, StatisticsState>(
      () => StatisticsViewModel(
        (ref) => GetStatisticsUseCase(ref.read(statisticsRepositoryProvider)),
      ),
    );
final exportViewModelProvider =
    NotifierProvider.autoDispose<ExportViewModel, ExportState>(
      () => ExportViewModel(
        (ref) => (
          catalog: LoadQuestionCatalogUseCase(
            ref.read(onboardingRepositoryProvider),
            ref.read(catalogRepositoryProvider),
          ),
          create: CreateExportUseCase(ref.read(exportRepositoryProvider)),
          download: DownloadExportUseCase(ref.read(exportRepositoryProvider)),
          save: SaveExportFileUseCase(ref.read(exportFileOpenerProvider)),
        ),
      ),
    );
final captureViewModelProvider =
    NotifierProvider<QuestionCaptureViewModel, CaptureState>(
      () => QuestionCaptureViewModel(
        (ref) => (
          pick: PickQuestionImageUseCase(ref.read(imagePickerProvider)),
          analyze: AnalyzeQuestionUseCase(ref.read(questionRepositoryProvider)),
        ),
      ),
    );
final confirmViewModelProvider = NotifierProvider.autoDispose
    .family<QuestionConfirmViewModel, ConfirmState, ConfirmationSeed>(
      (seed) => QuestionConfirmViewModel(
        seed,
        (ref) => (
          catalog: LoadQuestionCatalogUseCase(
            ref.read(onboardingRepositoryProvider),
            ref.read(catalogRepositoryProvider),
          ),
          create: CreateQuestionUseCase(ref.read(questionRepositoryProvider)),
        ),
      ),
    );
final topicPickerViewModelProvider =
    NotifierProvider.autoDispose<TopicPickerViewModel, String>(
      TopicPickerViewModel.new,
    );
final reviewSetupViewModelProvider =
    NotifierProvider<ReviewSetupViewModel, ReviewSetupState>(
      () => ReviewSetupViewModel(
        (ref) => (
          load: LoadReviewSetupUseCase(ref.read(reviewRepositoryProvider)),
          start: StartOrResumeReviewSessionUseCase(
            ref.read(reviewRepositoryProvider),
          ),
          options: GetReviewAnswerOptionsUseCase(
            ref.read(onboardingRepositoryProvider),
            ref.read(catalogRepositoryProvider),
          ),
        ),
      ),
    );
final reviewSessionViewModelProvider = NotifierProvider.autoDispose
    .family<ReviewSessionViewModel, ReviewSessionState, ReviewSessionContext>(
      (context) => ReviewSessionViewModel(
        context,
        (ref) => (
          next: GetNextReviewItemUseCase(ref.read(reviewRepositoryProvider)),
          submit: SubmitReviewAnswerUseCase(ref.read(reviewRepositoryProvider)),
        ),
      ),
    );
final reviewImageProvider = FutureProvider.autoDispose.family<ReviewImage, Uri>(
  (ref, uri) => ref.read(reviewRepositoryProvider).loadImage(uri),
);

final myQuestionsViewModelProvider =
    NotifierProvider<MyQuestionsViewModel, MyQuestionsState>(
      () => MyQuestionsViewModel(
        (ref) => GetQuestionsUseCase(ref.read(questionRepositoryProvider)),
      ),
    );
final questionDetailViewModelProvider = NotifierProvider.autoDispose
    .family<QuestionDetailViewModel, QuestionDetailState, String>(
      (id) => QuestionDetailViewModel(
        id,
        (ref) => (
          get: GetQuestionDetailUseCase(ref.read(questionRepositoryProvider)),
          archive: ArchiveQuestionUseCase(ref.read(questionRepositoryProvider)),
        ),
      ),
    );
final questionEditViewModelProvider = NotifierProvider.autoDispose
    .family<QuestionEditViewModel, QuestionEditState, String>(
      (id) => QuestionEditViewModel(
        id,
        (ref) => (
          get: GetQuestionDetailUseCase(ref.read(questionRepositoryProvider)),
          update: UpdateQuestionUseCase(ref.read(questionRepositoryProvider)),
          catalog: LoadQuestionCatalogUseCase(
            ref.read(onboardingRepositoryProvider),
            ref.read(catalogRepositoryProvider),
          ),
        ),
      ),
    );
final questionImageProvider = FutureProvider.autoDispose
    .family<QuestionImage, Uri>(
      (ref, uri) => ref.read(questionRepositoryProvider).loadImage(uri),
    );
final progressViewModelProvider =
    NotifierProvider<ProgressViewModel, ProgressState>(
      () => ProgressViewModel(
        (ref) => GetProgressUseCase(ref.read(progressRepositoryProvider)),
      ),
    );
final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(
      () => ProfileViewModel(
        (ref) => (
          get: GetProfileOverviewUseCase(
            ref.read(authRepositoryProvider),
            ref.read(onboardingRepositoryProvider),
            ref.read(progressRepositoryProvider),
          ),
          updateName: UpdateProfileNameUseCase(
            ref.read(authRepositoryProvider),
          ),
          updateGoal: UpdateDailyGoalUseCase(
            ref.read(onboardingRepositoryProvider),
          ),
        ),
      ),
    );
