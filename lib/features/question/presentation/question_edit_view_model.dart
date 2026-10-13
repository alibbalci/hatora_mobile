import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../catalog/domain/catalog.dart';
import '../domain/question.dart';
import '../domain/question_use_cases.dart';

class QuestionEditState {
  const QuestionEditState({
    this.loading = true,
    this.busy = false,
    this.question,
    this.answer = '',
    this.reason,
    this.difficulty,
    this.note = '',
    this.source = '',
    this.failure,
    this.saved,
    this.topics = const [],
    this.selectedTopic,
    this.answerOptionCount = 5,
  });
  final bool loading, busy;
  final int answerOptionCount;
  final Question? question, saved;
  final String answer, note, source;
  final MistakeReason? reason;
  final Difficulty? difficulty;
  final AppFailure? failure;
  final List<Topic> topics;
  final Topic? selectedTopic;
  int get changeCount {
    final q = question;
    if (q == null) return 0;
    return [
      answer != q.correctAnswer,
      reason != q.mistakeReason,
      difficulty != q.difficulty,
      note != q.shortNote,
      source != q.source,
      selectedTopic != null && selectedTopic!.id != q.topicId,
    ].where((v) => v).length;
  }

  QuestionEditState copyWith({
    bool? loading,
    bool? busy,
    String? answer,
    String? note,
    String? source,
    MistakeReason? reason,
    Difficulty? difficulty,
    AppFailure? failure,
    Question? saved,
    List<Topic>? topics,
    Topic? selectedTopic,
  }) => QuestionEditState(
    answerOptionCount: answerOptionCount,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    question: question,
    answer: answer ?? this.answer,
    reason: reason ?? this.reason,
    difficulty: difficulty ?? this.difficulty,
    note: note ?? this.note,
    source: source ?? this.source,
    failure: failure,
    saved: saved,
    topics: topics ?? this.topics,
    selectedTopic: selectedTopic ?? this.selectedTopic,
  );
}

class QuestionEditViewModel extends Notifier<QuestionEditState> {
  QuestionEditViewModel(this.id, this.resolve);
  final String id;
  final ({
    GetQuestionDetailUseCase get,
    UpdateQuestionUseCase update,
    LoadQuestionCatalogUseCase catalog,
  })
  Function(Ref)
  resolve;
  @override
  QuestionEditState build() {
    Future.microtask(load);
    return const QuestionEditState();
  }

  Future<void> load() async {
    try {
      final q = await resolve(ref).get(id);
      final catalog = await resolve(ref).catalog(examId: q.examId);
      if (ref.mounted) {
        state = QuestionEditState(
          loading: false,
          question: q,
          answerOptionCount: catalog.exam.answerOptionCount,
          answer: q.correctAnswer,
          reason: q.mistakeReason,
          difficulty: q.difficulty,
          note: q.shortNote,
          source: q.source,
          topics: catalog.topics,
          selectedTopic: catalog.topics
              .where((topic) => topic.id == q.topicId)
              .firstOrNull,
        );
      }
    } on AppFailure catch (e) {
      if (ref.mounted) state = QuestionEditState(loading: false, failure: e);
    }
  }

  void answer(String v) =>
      state = state.copyWith(answer: v.trim().toUpperCase());
  void reason(MistakeReason v) => state = state.copyWith(reason: v);
  void difficulty(Difficulty v) => state = state.copyWith(difficulty: v);
  void note(String v) => state = state.copyWith(note: v);
  void source(String v) => state = state.copyWith(source: v);
  void topic(Topic value) => state = state.copyWith(selectedTopic: value);
  void revert() {
    final q = state.question;
    if (q == null || state.busy) return;
    state = QuestionEditState(
      loading: false,
      question: q,
      answerOptionCount: state.answerOptionCount,
      answer: q.correctAnswer,
      reason: q.mistakeReason,
      difficulty: q.difficulty,
      note: q.shortNote,
      source: q.source,
      topics: state.topics,
      selectedTopic: state.topics.where((t) => t.id == q.topicId).firstOrNull,
    );
  }

  Future<void> submit() async {
    if (state.busy || state.question == null) return;
    if (!List.generate(
          state.answerOptionCount,
          (i) => String.fromCharCode(65 + i),
        ).contains(state.answer) ||
        state.reason == null ||
        state.difficulty == null ||
        state.note.length > 2000 ||
        state.source.length > 500) {
      state = state.copyWith(
        failure: const AppFailure(
          FailureKind.validation,
          fields: ['correctAnswer'],
        ),
      );
      return;
    }
    state = state.copyWith(busy: true);
    try {
      final q = await resolve(ref).update(
        id,
        QuestionUpdate(
          topicId: state.selectedTopic?.id ?? state.question!.topicId,
          correctAnswer: state.answer,
          mistakeReason: state.reason!,
          difficulty: state.difficulty!,
          shortNote: state.note,
          source: state.source,
        ),
      );
      if (ref.mounted) state = state.copyWith(busy: false, saved: q);
    } on AppFailure catch (e) {
      if (ref.mounted) state = state.copyWith(busy: false, failure: e);
    }
  }
}
