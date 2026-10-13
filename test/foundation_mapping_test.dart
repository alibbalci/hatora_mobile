import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/router.dart';
import 'package:hatora_mobile/app/routes.dart';
import 'package:hatora_mobile/core/config/app_config.dart';
import 'package:hatora_mobile/core/error/app_failure.dart';
import 'package:hatora_mobile/core/error/failure_mapper.dart';
import 'package:hatora_mobile/core/network/api_client.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/features/auth/domain/auth.dart';
import 'package:hatora_mobile/features/auth/presentation/auth_view_model.dart';
import 'package:hatora_mobile/features/catalog/data/catalog_dto.dart';
import 'package:hatora_mobile/features/catalog/data/catalog_mapper.dart';
import 'package:hatora_mobile/features/onboarding/data/onboarding_data.dart';
import 'package:hatora_mobile/features/question/data/question_dto.dart';
import 'package:hatora_mobile/features/question/data/question_mapper.dart';
import 'package:hatora_mobile/features/question/domain/question.dart';

import 'support/fakes.dart';

void main() {
  test(
    'AppConfig defaults to emulator and Dio accepts configurable URL/timeouts',
    () {
      expect(const AppConfig().apiBaseUrl, 'http://10.0.2.2:8080');
      final dio = createDio(
        const AppConfig(apiBaseUrl: 'https://api.example.test'),
      );
      expect(dio.options.baseUrl, 'https://api.example.test');
      expect(dio.options.connectTimeout, const Duration(seconds: 15));
      expect(dio.options.receiveTimeout, const Duration(seconds: 60));
      dio.close();
    },
  );
  test('theme uses the semantic Hatora palette tokens', () {
    final theme = buildAppTheme();
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.accent);
    expect(theme.appBarTheme.foregroundColor, AppColors.primaryInk);
  });
  test('router guards all three session states', () {
    expect(
      sessionRedirect(const AuthState(), Routes.home, hasExamSelection: false),
      Routes.splash,
    );
    expect(
      sessionRedirect(
        const AuthState(status: AuthStatus.guest),
        Routes.home,
        hasExamSelection: false,
      ),
      Routes.welcome,
    );
    expect(
      sessionRedirect(
        const AuthState(
          status: AuthStatus.authenticated,
          user: UserProfile(
            id: 'u',
            displayName: 'Ada',
            onboardingCompleted: false,
          ),
        ),
        Routes.auth,
        hasExamSelection: true,
      ),
      Routes.value,
    );
    expect(
      sessionRedirect(
        const AuthState(status: AuthStatus.authenticated, user: user),
        Routes.auth,
        hasExamSelection: false,
      ),
      Routes.home,
    );
  });
  test('backend validation details retain field names but not raw messages or rejected secrets', () {
    final request = RequestOptions(path: '/api/questions');
    final error = DioException(
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: 400,
        data: {
          'code': 'VALIDATION_ERROR',
          'message': 'secret stack trace',
          'details': {
            'fieldErrors': [
              {
                'field': 'difficulty',
                'message': 'raw',
                'rejectedValue': 'secret',
              },
            ],
          },
        },
      ),
    );
    final failure = mapFailure(error);
    expect(failure.kind, FailureKind.validation);
    expect(failure.fields, ['difficulty']);
    expect(failure.message, isNot(contains('secret')));
  });
  test('catalog and onboarding mappings preserve real catalog ids', () {
    final exam = mapExam(
      ExamDto.fromJson({
        'id': 'e',
        'name': 'LGS',
        'code': 'LGS',
        'answerOptionCount': 4,
      }),
    );
    expect(exam.answerOptionCount, 4);
    final state = mapOnboarding(
      OnboardingDto.fromJson({
        'onboardingCompleted': false,
        'dailyReviewGoal': 10,
        'activeExam': null,
      }),
    );
    expect(state.examId, null);
    expect(state.completed, false);
  });
  test(
    'analysis mapping preserves advisory flag, ids, confidence and expiration',
    () {
      final result = mapAnalysis(
        QuestionAnalysisDto.fromJson({
          'id': 'a',
          'status': 'FAILED',
          'manualSelectionRequired': true,
          'imageAccessUri': '/api/files/temp/user/a.png',
          'suggestedTopicId': 'topic',
          'suggestedSubjectId': 'subject',
          'suggestedSectionId': 'section',
          'confidence': 0.4,
          'expiresAt': '2030-01-01T00:00:00Z',
        }),
      );
      expect(result.status, AnalysisStatus.failed);
      expect(result.manualSelectionRequired, true);
      expect(result.suggestedTopicId, 'topic');
      expect(result.confidence, .4);
      expect(result.expiresAt.isUtc, true);
    },
  );
  test('create payload uses exact backend enum values and no client exam or subject', () {
    for (final reason in MistakeReason.values) {
      final json = mapQuestionRequest(
        QuestionDraft(
          analysisId: 'a',
          topicId: 't',
          correctAnswer: 'B',
          mistakeReason: reason,
          difficulty: Difficulty.hard,
        ),
      );
      expect(json['mistakeReason'], mistakeReasonWire[reason]);
      expect(json['difficulty'], 'HARD');
      expect(
        json.keys,
        unorderedEquals([
          'analysisId',
          'topicId',
          'correctAnswer',
          'mistakeReason',
          'difficulty',
          'shortNote',
          'source',
        ]),
      );
    }
    expect(
      mistakeReasonWire.values,
      unorderedEquals([
        'CARELESSNESS',
        'CONCEPT_GAP',
        'CALCULATION_ERROR',
        'MISREAD',
        'FORGOT_INFORMATION',
        'TIME_PRESSURE',
        'OTHER',
      ]),
    );
  });
  test(
    'question response maps server schedule without computing review rules',
    () {
      final result = mapQuestion(
        QuestionDto.fromJson({
          'id': 'q',
          'topicName': 'Türev',
          'subjectName': 'Matematik',
          'correctAnswer': 'A',
          'difficulty': 'HARD',
          'mistakeReason': 'MISREAD',
          'nextReviewDate': '2026-10-01',
          'imageAccessUri': '/api/files/questions/user/q.png',
        }),
      );
      expect(result.nextReviewDate, DateTime(2026, 10, 1));
      expect(result.mistakeReason, MistakeReason.misread);
    },
  );
}
