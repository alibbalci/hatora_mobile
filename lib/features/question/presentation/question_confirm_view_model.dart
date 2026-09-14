import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../catalog/domain/catalog.dart';
import '../domain/question.dart';
import '../domain/question_use_cases.dart';

class ConfirmState {
  const ConfirmState({
    this.catalog = const AsyncLoading(),
    this.topic,
    this.answer,
    this.mistakeReason,
    this.difficulty,
    this.shortNote = '',
    this.source = '',
    this.busy = false,
    this.failure,
    this.fieldErrors = const {},
    this.created,
  });
  final AsyncValue<QuestionCatalog> catalog;
  final Topic? topic;
  final String? answer;
  final MistakeReason? mistakeReason;
  final Difficulty? difficulty;
  final String shortNote, source;
  final bool busy;
  final AppFailure? failure;
  final Set<String> fieldErrors;
  final Question? created;
  ConfirmState copyWith({
    AsyncValue<QuestionCatalog>? catalog,
    Topic? topic,
    String? answer,
    MistakeReason? mistakeReason,
    Difficulty? difficulty,
    String? shortNote,
    String? source,
    bool? busy,
    AppFailure? failure,
    Set<String>? fieldErrors,
    Question? created,
  }) => ConfirmState(
    catalog: catalog ?? this.catalog,
    topic: topic ?? this.topic,
    answer: answer ?? this.answer,
    mistakeReason: mistakeReason ?? this.mistakeReason,
    difficulty: difficulty ?? this.difficulty,
    shortNote: shortNote ?? this.shortNote,
    source: source ?? this.source,
    busy: busy ?? this.busy,
    failure: failure,
    fieldErrors: fieldErrors ?? const {},
    created: created ?? this.created,
  );
}

class QuestionConfirmViewModel extends Notifier<ConfirmState> {
  QuestionConfirmViewModel(this.seed, this.resolve);
  final ConfirmationSeed seed;
  final ({LoadQuestionCatalogUseCase catalog, CreateQuestionUseCase create})
  Function(Ref)
  resolve;
  @override
  ConfirmState build() {
    Future.microtask(load);
    return const ConfirmState();
  }

  Future<void> load() async {
    state = state.copyWith(catalog: const AsyncLoading());
    final catalog = await AsyncValue.guard(resolve(ref).catalog.call);
    if (!ref.mounted) return;
    // TR: AI önerisi formu doldurmaz; kullanıcı konuyu açıkça seçer/onaylar.
    // EN: AI is advisory; the user explicitly selects or accepts a topic.
    state = state.copyWith(catalog: catalog);
  }

  Topic? get suggestedTopic {
    final matches = state.catalog.asData?.value.topics.where(
      (t) => t.id == seed.analysis.suggestedTopicId,
    );
    return matches == null || matches.isEmpty ? null : matches.first;
  }

  void selectTopic(Topic topic) {
    if (!state.busy &&
        state.catalog.asData?.value.topics.any((t) => t.id == topic.id) ==
            true) {
      state = state.copyWith(topic: topic);
    }
  }

  void setAnswer(String answer) {
    if (!state.busy) state = state.copyWith(answer: answer);
  }

  void setReason(MistakeReason reason) {
    if (!state.busy) state = state.copyWith(mistakeReason: reason);
  }

  void setDifficulty(Difficulty value) {
    if (!state.busy) state = state.copyWith(difficulty: value);
  }

  void setNote(String value) {
    if (!state.busy) state = state.copyWith(shortNote: value);
  }

  void setSource(String value) {
    if (!state.busy) state = state.copyWith(source: value);
  }

  Future<void> submit() async {
    if (state.busy || state.created != null) return;
    final catalog = state.catalog.asData?.value;
    final fields = <String>{
      if (state.topic == null) 'topicId',
      if (state.answer == null ||
          catalog == null ||
          !List.generate(
            catalog.exam.answerOptionCount,
            (i) => String.fromCharCode(65 + i),
          ).contains(state.answer))
        'correctAnswer',
      if (state.mistakeReason == null) 'mistakeReason',
      if (state.difficulty == null) 'difficulty',
      if (state.shortNote.length > 2000) 'shortNote',
      if (state.source.length > 500) 'source',
    };
    if (fields.isNotEmpty) {
      state = state.copyWith(
        fieldErrors: Set.unmodifiable(fields),
        failure: const AppFailure(FailureKind.validation),
      );
      return;
    }
    state = state.copyWith(busy: true);
    final draft = QuestionDraft(
      analysisId: seed.analysis.id,
      topicId: state.topic!.id,
      correctAnswer: state.answer!,
      mistakeReason: state.mistakeReason!,
      difficulty: state.difficulty!,
      shortNote: state.shortNote,
      source: state.source,
    );
    try {
      final question = await resolve(ref).create(draft);
      if (ref.mounted) state = state.copyWith(busy: false, created: question);
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = state.copyWith(
          busy: false,
          failure: failure,
          fieldErrors: failure.fields.toSet(),
        );
      }
    }
  }
}
