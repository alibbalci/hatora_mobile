import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/features/question/domain/question.dart';
import 'package:hatora_mobile/features/review/domain/review_models.dart';
import 'package:hatora_mobile/features/review/presentation/question_learned_moment.dart';

import 'support/fakes.dart';

class LearnedQuestionRepository extends FakeQuestionRepository {
  @override
  Future<Question> getQuestion(String id) async => Question(
    id: id,
    topicName: 'Rasyonel sayılar',
    subjectName: 'Matematik',
    correctAnswer: 'B',
    difficulty: Difficulty.medium,
    mistakeReason: MistakeReason.conceptGap,
    status: QuestionStatus.mastered,
    createdAt: DateTime(2026, 10, 12),
  );
}

void main() {
  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets(
      'learned celebration uses real date and advances only on tap at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var next = 0;
        final c = ProviderContainer(
          overrides: [
            questionRepositoryProvider.overrideWithValue(
              LearnedQuestionRepository(),
            ),
          ],
        );
        addTearDown(c.dispose);
        final item = NextReviewItem(
          itemId: 'i',
          questionId: 'q',
          position: 3,
          totalItems: 8,
          topicId: 't',
          topicName: 'Rasyonel sayılar',
          subjectId: 's',
          subjectName: 'Matematik',
          examCode: 'KPSS',
          imageUri: Uri.parse('/image'),
          difficulty: Difficulty.medium,
        );
        final result = AnswerResult(
          itemId: 'i',
          questionId: 'q',
          skipped: false,
          correctAnswer: 'B',
          selectedAnswer: 'B',
          result: ReviewResult.correct,
          previousStage: 5,
          newStage: 5,
          nextReviewDate: null,
          questionStatus: 'MASTERED',
          mastered: true,
          solutionImages: const [],
          imageUri: Uri.parse('/image'),
          sessionCompleted: false,
          mistakeReason: MistakeReason.conceptGap,
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              theme: buildAppTheme(),
              home: QuestionLearnedMoment(
                item: item,
                result: result,
                answerCount: 5,
                image: selectedImage.bytes,
                onNext: () => next++,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Öğrenildi'), findsOneWidget);
        expect(find.text('12 Eki'), findsOneWidget);
        expect(find.text('5 aşama'), findsOneWidget);
        expect(next, 0);
        await tester.tap(find.text('Sonraki soru'));
        await tester.pump();
        expect(next, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
