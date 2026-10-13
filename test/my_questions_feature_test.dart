import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/error/app_failure.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/features/question/data/question_dto.dart';
import 'package:hatora_mobile/features/question/data/question_mapper.dart';
import 'package:hatora_mobile/features/question/domain/question.dart';
import 'package:hatora_mobile/features/question/presentation/my_questions_screens.dart';
import 'package:hatora_mobile/features/question/presentation/my_questions_view_model.dart';

import 'support/fakes.dart';

QuestionSummary summary({DateTime? nextReviewDate}) => QuestionSummary(
  id: '550e8400-e29b-41d4-a716-446655440000',
  topicId: 'topic',
  topicName:
      'Çok uzun bir konu adı taşmaya neden olmamalı ve iki satırda kalmalı',
  subjectId: 'subject',
  subjectName: 'Matematik',
  examCode: 'TYT',
  correctAnswer: 'B',
  difficulty: Difficulty.hard,
  mistakeReason: MistakeReason.misread,
  reviewStage: 1,
  status: QuestionStatus.active,
  createdAt: DateTime.utc(2026, 9, 13),
  nextReviewDate: nextReviewDate,
);

void main() {
  test('summary DTO maps pagination and unknown status safely', () {
    final page = mapQuestionPage(
      QuestionPageDto.fromJson({
        'content': [
          {
            'id': 'q',
            'topicId': 't',
            'topicName': 'Türev',
            'subjectId': 's',
            'subjectName': 'Matematik',
            'examCode': 'TYT',
            'imageAccessUri': null,
            'correctAnswer': 'A',
            'difficulty': 'HARD',
            'mistakeReason': 'MISREAD',
            'reviewStage': 1,
            'nextReviewDate': null,
            'status': 'FUTURE_STATUS',
            'createdAt': '2026-09-13T10:00:00Z',
          },
        ],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
        'first': true,
        'last': true,
      }),
    );
    expect(page.items.single.status, QuestionStatus.unknown);
    expect(page.last, true);
    expect(page.page, 0);
  });
  test('detail maps optional nulls and solution images', () {
    final q = mapQuestion(
      QuestionDto.fromJson({
        'id': 'q',
        'topicId': 't',
        'topicName': 'Türev',
        'subjectId': 's',
        'subjectName': 'Matematik',
        'sectionName': 'Sayısal',
        'examCode': 'TYT',
        'imageAccessUri': null,
        'correctAnswer': 'A',
        'difficulty': 'EASY',
        'mistakeReason': 'OTHER',
        'shortNote': null,
        'source': null,
        'reviewStage': 0,
        'nextReviewDate': '2026-09-14',
        'status': 'ACTIVE',
        'firstReviewedAt': null,
        'createdAt': '2026-09-13T10:00:00Z',
        'updatedAt': '2026-09-13T10:00:00Z',
        'solutionImages': [
          {'id': 'i', 'imageAccessUri': '/image', 'sortOrder': 0},
        ],
      }),
    );
    expect(q.shortNote, '');
    expect(q.solutionImages.single.sortOrder, 0);
    expect(q.nextReviewDate, DateTime(2026, 9, 14));
  });
  test(
    'active question due tomorrow remains visible in My Questions state',
    () async {
      final repo = FakeQuestionRepository()
        ..page = QuestionPage(
          items: [
            summary(
              nextReviewDate: DateTime.now().add(const Duration(days: 1)),
            ),
          ],
          page: 0,
          size: 20,
          totalElements: 1,
          totalPages: 1,
          first: true,
          last: true,
        );
      final c = ProviderContainer(
        overrides: [questionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      c.read(myQuestionsViewModelProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(myQuestionsViewModelProvider).items, hasLength(1));
      expect(repo.listCalls, 1);
    },
  );
  test('pagination appends and blocks duplicate/final load more', () async {
    final repo = FakeQuestionRepository()
      ..page = QuestionPage(
        items: [summary()],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
        first: true,
        last: true,
      );
    final c = ProviderContainer(
      overrides: [questionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    c.read(myQuestionsViewModelProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await c.read(myQuestionsViewModelProvider.notifier).loadMore();
    expect(repo.listCalls, 1);
  });
  test('list failure is normalized state and retryable', () async {
    final repo = FakeQuestionRepository()
      ..listFailure = const AppFailure(FailureKind.network);
    final c = ProviderContainer(
      overrides: [questionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    c.read(myQuestionsViewModelProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(myQuestionsViewModelProvider).phase, MyQuestionsPhase.error);
    expect(
      c.read(myQuestionsViewModelProvider).failure?.kind,
      FailureKind.network,
    );
  });
  testWidgets('card shows tomorrow date and long text without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: QuestionSummaryCard(
                question: summary(
                  nextReviewDate: DateTime.now().add(const Duration(days: 1)),
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Yarın'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
