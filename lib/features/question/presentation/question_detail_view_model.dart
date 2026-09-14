import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../domain/question.dart';
import '../domain/question_use_cases.dart';

enum QuestionDetailPhase { loading, ready, archiving, archived, error }

class QuestionDetailState {
  const QuestionDetailState({
    this.phase = QuestionDetailPhase.loading,
    this.question,
    this.failure,
  });
  final QuestionDetailPhase phase;
  final Question? question;
  final AppFailure? failure;
}

class QuestionDetailViewModel extends Notifier<QuestionDetailState> {
  QuestionDetailViewModel(this.id, this.resolve);
  final String id;
  final ({GetQuestionDetailUseCase get, ArchiveQuestionUseCase archive})
  Function(Ref)
  resolve;
  @override
  QuestionDetailState build() {
    Future.microtask(load);
    return const QuestionDetailState();
  }

  Future<void> load() async {
    state = QuestionDetailState(question: state.question);
    try {
      final q = await resolve(ref).get(id);
      if (ref.mounted) {
        state = QuestionDetailState(
          phase: QuestionDetailPhase.ready,
          question: q,
        );
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = QuestionDetailState(
          phase: QuestionDetailPhase.error,
          question: state.question,
          failure: e,
        );
      }
    }
  }

  Future<void> archive() async {
    if (state.phase != QuestionDetailPhase.ready) return;
    final q = state.question;
    state = QuestionDetailState(
      phase: QuestionDetailPhase.archiving,
      question: q,
    );
    try {
      await resolve(ref).archive(id);
      if (ref.mounted) {
        state = QuestionDetailState(
          phase: QuestionDetailPhase.archived,
          question: q,
        );
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = QuestionDetailState(
          phase: QuestionDetailPhase.ready,
          question: q,
          failure: e,
        );
      }
    }
  }
}
