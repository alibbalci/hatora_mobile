import 'dart:async';

import 'package:hatora_mobile/features/catalog/domain/exam_schedule.dart';

import 'dart:convert';
import 'dart:typed_data';

import 'package:hatora_mobile/core/error/app_failure.dart';
import 'package:hatora_mobile/core/storage/token_storage.dart';
import 'package:hatora_mobile/features/auth/domain/auth.dart';
import 'package:hatora_mobile/features/catalog/domain/catalog.dart';
import 'package:hatora_mobile/features/dashboard/domain/dashboard_models.dart';
import 'package:hatora_mobile/features/dashboard/domain/dashboard_repository.dart';
import 'package:hatora_mobile/features/export/domain/export_models.dart';
import 'package:hatora_mobile/features/export/domain/export_repository.dart';
import 'package:hatora_mobile/features/onboarding/domain/onboarding.dart';
import 'package:hatora_mobile/features/progress/domain/progress_models.dart';
import 'package:hatora_mobile/features/progress/domain/progress_repository.dart';
import 'package:hatora_mobile/features/question/domain/question.dart';
import 'package:hatora_mobile/features/statistics/domain/statistics_models.dart';
import 'package:hatora_mobile/features/statistics/domain/statistics_repository.dart';

const exam = Exam(
  id: 'exam',
  name: 'Test sınavı',
  code: 'TEST',
  answerOptionCount: 4,
);
const choice = ExamChoice(editionId: 'edition', exam: exam, year: 2026);
const topic = Topic(
  id: 'topic',
  name: 'Türev',
  subjectId: 'subject',
  subjectName: 'Matematik',
  sectionId: 'section',
  sectionName: 'Alan',
);
const user = UserProfile(
  id: 'user',
  displayName: 'Ada',
  onboardingCompleted: true,
);
final selectedImage = SelectedImage(
  bytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
  ),
  name: 'question.png',
  mimeType: 'image/png',
);
final analysis = QuestionAnalysis(
  id: 'analysis',
  status: AnalysisStatus.completed,
  manualSelectionRequired: false,
  suggestedTopicId: topic.id,
  expiresAt: DateTime.utc(2030),
);
final seed = ConfirmationSeed(analysis, selectedImage);
const question = Question(
  id: 'question',
  topicName: 'Türev',
  subjectName: 'Matematik',
  correctAnswer: 'B',
  difficulty: Difficulty.medium,
  mistakeReason: MistakeReason.conceptGap,
);

class MemoryTokenStorage implements TokenStorage {
  TokenPair? pair;
  @override
  Future<TokenPair?> read() async => pair;
  @override
  Future<void> write(TokenPair tokens) async {
    pair = tokens;
  }

  @override
  Future<void> clear() async {
    pair = null;
  }
}

class FakeAuthRepository implements AuthRepository {
  UserProfile? session;
  AppFailure? failure;
  Completer<UserProfile>? pending;
  int loginCalls = 0, registerCalls = 0;
  int profileCalls = 0, updateProfileCalls = 0;
  String? lastEmail;
  final events = StreamController<void>.broadcast();
  @override
  Stream<void> get invalidated => events.stream;
  @override
  Future<UserProfile?> restore() async => session;
  @override
  Future<UserProfile> login(String email, String password) async {
    loginCalls++;
    lastEmail = email;
    if (failure != null) throw failure!;
    return pending?.future ?? user;
  }

  @override
  Future<UserProfile> register(
    String email,
    String password,
    String displayName,
  ) async {
    registerCalls++;
    if (failure != null) throw failure!;
    return user;
  }

  @override
  Future<void> logout() async {
    session = null;
  }

  @override
  Future<UserProfile> profile() async {
    profileCalls++;
    if (failure != null) throw failure!;
    return session ?? user;
  }

  @override
  Future<UserProfile> updateDisplayName(String displayName) async {
    updateProfileCalls++;
    if (failure != null) throw failure!;
    final current = session ?? user;
    return UserProfile(
      id: current.id,
      displayName: displayName,
      onboardingCompleted: current.onboardingCompleted,
      email: current.email,
      authProvider: current.authProvider,
      createdAt: current.createdAt,
    );
  }
}

class FakeCatalogRepository implements CatalogRepository {
  @override
  Future<List<ExamSessionSchedule>> examSessions(
    String examId,
    String editionId,
  ) async => const [];
  @override
  Future<List<ExamChoice>> examChoices() async => [choice];
  @override
  Future<QuestionCatalog> questionCatalog(String examId) async =>
      const QuestionCatalog(exam, [topic]);
}

class FakeOnboardingRepository implements OnboardingRepository {
  @override
  Future<OnboardingStatus> activateExam(String editionId) =>
      complete(editionId, 10);
  int completeCalls = 0;
  @override
  Future<OnboardingStatus> status() async => const OnboardingStatus(
    completed: true,
    dailyReviewGoal: 10,
    examId: 'exam',
    examEditionId: 'edition',
    examDisplay: 'Test sınavı · 2026',
  );
  @override
  Future<OnboardingStatus> complete(String editionId, int dailyGoal) async {
    completeCalls++;
    return OnboardingStatus(
      completed: true,
      dailyReviewGoal: dailyGoal,
      examId: 'exam',
      examEditionId: editionId,
    );
  }

  @override
  Future<int> updateDailyReviewGoal(int dailyGoal) async => dailyGoal;
}

class FakePicker implements ImagePickerService {
  SelectedImage? next = selectedImage;
  SelectedImage? recovered;
  @override
  Future<SelectedImage?> pick(ImageOrigin origin) async => next;
  @override
  Future<SelectedImage?> recover() async => recovered;
}

class FakeQuestionRepository implements QuestionRepository {
  QuestionAnalysis nextAnalysis = analysis;
  AppFailure? analyzeFailure, createFailure;
  QuestionDraft? lastDraft;
  int createCalls = 0;
  Completer<Question>? pendingCreate;
  @override
  Future<QuestionAnalysis> analyze(SelectedImage image) async {
    if (analyzeFailure != null) throw analyzeFailure!;
    return nextAnalysis;
  }

  @override
  Future<Question> create(QuestionDraft draft) async {
    createCalls++;
    lastDraft = draft;
    if (createFailure != null) throw createFailure!;
    return pendingCreate?.future ?? question;
  }

  QuestionPage page = const QuestionPage(
    items: [],
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
    first: true,
    last: true,
  );
  AppFailure? listFailure, detailFailure, updateFailure, archiveFailure;
  int listCalls = 0, archiveCalls = 0;
  @override
  Future<QuestionPage> getQuestions({
    int page = 0,
    int size = 20,
    QuestionFilters filters = const QuestionFilters(),
  }) async {
    listCalls++;
    if (listFailure != null) throw listFailure!;
    return this.page;
  }

  @override
  Future<Question> getQuestion(String id) async {
    if (detailFailure != null) throw detailFailure!;
    return question;
  }

  @override
  Future<Question> updateQuestion(String id, QuestionUpdate update) async {
    if (updateFailure != null) throw updateFailure!;
    return question;
  }

  @override
  Future<void> archiveQuestion(String id) async {
    archiveCalls++;
    if (archiveFailure != null) throw archiveFailure!;
  }

  @override
  Future<QuestionImage> loadImage(Uri uri) async =>
      QuestionImage(Uint8List(0), null);
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

final dailyProgress = DailyProgress(
  activityDate: DateTime(2026, 9, 13),
  reviewGoal: 10,
  effectiveReviewGoal: 3,
  reviewsCompleted: 2,
  correctCount: 1,
  wrongCount: 1,
  unsolvedCount: 0,
  questionsMastered: 0,
  goalCompleted: false,
  xpEarned: 5,
);
final userProgress = UserProgress(
  totalXp: 120,
  level: 2,
  currentStreak: 4,
  longestStreak: 8,
  lastCompletedActivityDate: null,
  today: dailyProgress,
);

class FakeProgressRepository implements ProgressRepository {
  UserProgress progress = userProgress;
  AppFailure? failure;
  int calls = 0;
  @override
  Future<UserProgress> getProgress() async {
    calls++;
    if (failure != null) throw failure!;
    return progress;
  }
}

final dashboardSummary = DashboardSummary(
  activeExam: const DashboardActiveExam(
    examId: 'exam',
    examEditionId: 'edition',
    examName: 'Test sınavı',
    examYear: 2026,
    examDate: null,
    daysUntilExam: null,
  ),
  review: const DashboardReviewSummary(
    dueCount: 5,
    reviewsCompletedToday: 3,
    effectiveReviewGoal: 8,
    goalCompleted: false,
    hasActiveReviewSession: false,
    activeReviewSessionId: null,
  ),
  progress: const DashboardProgressSummary(
    totalXp: 120,
    level: 2,
    currentStreak: 4,
    longestStreak: 8,
  ),
  questions: const DashboardQuestionSummary(activeCount: 12, masteredCount: 3),
);

class FakeDashboardRepository implements DashboardRepository {
  DashboardSummary summary = dashboardSummary;
  AppFailure? failure;
  int calls = 0;
  @override
  Future<DashboardSummary> getDashboard() async {
    calls++;
    if (failure != null) throw failure!;
    return summary;
  }
}

const generalStatistics = GeneralStatistics(
  totalQuestionsAdded: 20,
  totalReviews: 10,
  correctCount: 6,
  wrongCount: 3,
  unsolvedCount: 1,
  successRate: 60.0,
  activeQuestionCount: 15,
  masteredQuestionCount: 5,
  currentStreak: 4,
  longestStreak: 8,
);
const statisticsBundle = StatisticsBundle(
  general: generalStatistics,
  subjects: [],
  topics: [],
  mistakeReasons: [],
  insights: LearningInsights(
    strongestSubjects: [],
    weakestSubjects: [],
    strongestTopics: [],
    weakestTopics: [],
    hardestTopics: [],
  ),
);

class FakeStatisticsRepository implements StatisticsRepository {
  AppFailure? failure;
  GeneralStatistics general = generalStatistics;
  List<SubjectStatistics> subjects = const [];
  List<TopicStatistics> topics = const [];
  List<MistakeReasonStatistics> mistakeReasons = const [];
  LearningInsights insights = statisticsBundle.insights;
  StatsRange? lastRange;
  @override
  Future<GeneralStatistics> getGeneral(StatsRange range) async {
    lastRange = range;
    if (failure != null) throw failure!;
    return general;
  }

  @override
  Future<List<SubjectStatistics>> getSubjects(StatsRange range) async {
    lastRange = range;
    if (failure != null) throw failure!;
    return subjects;
  }

  @override
  Future<List<TopicStatistics>> getTopics(StatsRange range) async {
    lastRange = range;
    if (failure != null) throw failure!;
    return topics;
  }

  @override
  Future<List<MistakeReasonStatistics>> getMistakeReasons(
    StatsRange range,
  ) async {
    lastRange = range;
    if (failure != null) throw failure!;
    return mistakeReasons;
  }

  @override
  Future<LearningInsights> getInsights(StatsRange range) async {
    lastRange = range;
    if (failure != null) throw failure!;
    return insights;
  }
}

final exportJob = ExportJob(
  id: 'export-1',
  status: ExportJobStatus.completed,
  createdAt: DateTime.utc(2026, 9, 13),
  completedAt: DateTime.utc(2026, 9, 13),
  downloadUri: Uri.parse('/api/exports/export-1/download'),
);

class FakeExportRepository implements ExportRepository {
  @override
  Future<ExportOptions> options() async =>
      const ExportOptions(1, [ExportSubjectCount('subject', 'Matematik', 1)]);
  ExportJob job = exportJob;
  AppFailure? createFailure, getFailure, downloadFailure;
  String? lastSubjectId, lastTopicId;
  int createCalls = 0, downloadCalls = 0;
  @override
  Future<ExportJob> createExport({String? subjectId, String? topicId}) async {
    createCalls++;
    lastSubjectId = subjectId;
    lastTopicId = topicId;
    if (createFailure != null) throw createFailure!;
    return job;
  }

  @override
  Future<ExportJob> getExport(String id) async {
    if (getFailure != null) throw getFailure!;
    return job;
  }

  @override
  Future<ExportFile> download(String id) async {
    downloadCalls++;
    if (downloadFailure != null) throw downloadFailure!;
    return ExportFile(Uint8List.fromList([1, 2, 3]), 'application/pdf');
  }
}

class FakeExportFileOpener implements ExportFileOpener {
  int openCalls = 0;
  String? lastFileName;
  Uint8List? lastBytes;
  AppFailure? failure;
  @override
  Future<void> open(Uint8List bytes, String fileName) async {
    openCalls++;
    lastFileName = fileName;
    lastBytes = bytes;
    if (failure != null) throw failure!;
  }
}
