import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../domain/question.dart';
import '../domain/question_use_cases.dart';

enum MyQuestionsPhase {
  initialLoading,
  ready,
  empty,
  loadingMore,
  refreshing,
  error,
}

class MyQuestionsState {
  const MyQuestionsState({
    this.phase = MyQuestionsPhase.initialLoading,
    this.items = const [],
    this.page = -1,
    this.hasNext = false,
    this.filters = const QuestionFilters(status: QuestionStatus.active),
    this.failure,
    this.totalCount = 0,
  });
  final MyQuestionsPhase phase;
  final List<QuestionSummary> items;
  final int page, totalCount;
  final bool hasNext;
  final QuestionFilters filters;
  final AppFailure? failure;
}

class MyQuestionsViewModel extends Notifier<MyQuestionsState> {
  MyQuestionsViewModel(this.resolve);
  final GetQuestionsUseCase Function(Ref) resolve;
  bool _requesting = false;
  int _generation = 0;
  @override
  MyQuestionsState build() {
    Future.microtask(load);
    return const MyQuestionsState();
  }

  Future<void> load() => _fetch(reset: true);
  Future<void> refresh() => _fetch(reset: true, refreshing: true);
  Future<void> retry() => _fetch(reset: state.items.isEmpty);
  Future<void> loadMore() => _fetch(reset: false);
  Future<void> setFilters(QuestionFilters filters) async {
    _generation++;
    _requesting = false;
    state = MyQuestionsState(filters: filters);
    await _fetch(reset: true);
  }

  Future<void> removeArchived(String id) async {
    final items = state.items.where((q) => q.id != id).toList();
    state = MyQuestionsState(
      phase: items.isEmpty ? MyQuestionsPhase.empty : MyQuestionsPhase.ready,
      items: items,
      page: state.page,
      hasNext: state.hasNext,
      filters: state.filters,
    );
  }

  Future<void> _fetch({required bool reset, bool refreshing = false}) async {
    if (_requesting || (!reset && !state.hasNext)) return;
    _requesting = true;
    final generation = _generation;
    final old = state;
    state = MyQuestionsState(
      phase: refreshing
          ? MyQuestionsPhase.refreshing
          : reset
          ? MyQuestionsPhase.initialLoading
          : MyQuestionsPhase.loadingMore,
      items: old.items,
      page: old.page,
      totalCount: old.totalCount,
      hasNext: old.hasNext,
      filters: old.filters,
    );
    try {
      final result = await resolve(ref)(
        page: reset ? 0 : old.page + 1,
        filters: old.filters,
      );
      if (!ref.mounted || generation != _generation) return;
      final items = reset
          ? result.items
          : [
              ...old.items,
              ...result.items.where(
                (q) => old.items.every((e) => e.id != q.id),
              ),
            ];
      state = MyQuestionsState(
        phase: items.isEmpty ? MyQuestionsPhase.empty : MyQuestionsPhase.ready,
        items: items,
        page: result.page,
        totalCount: result.totalElements,
        hasNext: !result.last,
        filters: old.filters,
      );
    } on AppFailure catch (failure) {
      if (ref.mounted && generation == _generation) {
        state = MyQuestionsState(
          phase: MyQuestionsPhase.error,
          items: old.items,
          page: old.page,
          totalCount: old.totalCount,
          hasNext: old.hasNext,
          filters: old.filters,
          failure: failure,
        );
      }
    } finally {
      if (generation == _generation) _requesting = false;
    }
  }
}
