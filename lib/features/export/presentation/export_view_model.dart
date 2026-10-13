import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../catalog/domain/catalog.dart';
import '../../question/domain/question_use_cases.dart';
import '../domain/export_models.dart';
import '../domain/export_use_cases.dart';

enum ExportPhase { idle, submitting, result, downloading }

class ExportState {
  const ExportState({
    this.catalog = const AsyncLoading(),
    this.phase = ExportPhase.idle,
    this.subjectId,
    this.subjectName,
    this.topicId,
    this.topicName,
    this.job,
    this.failure,
    this.downloadFailure,
  });
  final AsyncValue<QuestionCatalog> catalog;
  final ExportPhase phase;
  final String? subjectId, subjectName, topicId, topicName;
  final ExportJob? job;
  final AppFailure? failure;
  final AppFailure? downloadFailure;

  ExportState copyWith({
    AsyncValue<QuestionCatalog>? catalog,
    ExportPhase? phase,
    Object? subjectId = _sentinel,
    Object? subjectName = _sentinel,
    Object? topicId = _sentinel,
    Object? topicName = _sentinel,
    Object? job = _sentinel,
    AppFailure? failure,
    AppFailure? downloadFailure,
  }) => ExportState(
    catalog: catalog ?? this.catalog,
    phase: phase ?? this.phase,
    subjectId: identical(subjectId, _sentinel)
        ? this.subjectId
        : subjectId as String?,
    subjectName: identical(subjectName, _sentinel)
        ? this.subjectName
        : subjectName as String?,
    topicId: identical(topicId, _sentinel) ? this.topicId : topicId as String?,
    topicName: identical(topicName, _sentinel)
        ? this.topicName
        : topicName as String?,
    job: identical(job, _sentinel) ? this.job : job as ExportJob?,
    failure: failure,
    downloadFailure: downloadFailure,
  );
}

const _sentinel = Object();

class ExportViewModel extends Notifier<ExportState> {
  ExportViewModel(this.resolve);
  final ({
    LoadQuestionCatalogUseCase catalog,
    CreateExportUseCase create,
    DownloadExportUseCase download,
    SaveExportFileUseCase save,
  })
  Function(Ref)
  resolve;

  @override
  ExportState build() {
    Future.microtask(load);
    return const ExportState();
  }

  Future<void> load() async {
    state = state.copyWith(catalog: const AsyncLoading());
    final catalog = await AsyncValue.guard(resolve(ref).catalog.call);
    if (ref.mounted) state = state.copyWith(catalog: catalog);
  }

  void selectSubject(String? subjectId, String? subjectName) {
    if (state.phase != ExportPhase.idle) return;
    state = state.copyWith(
      subjectId: subjectId,
      subjectName: subjectName,
      topicId: null,
      topicName: null,
    );
  }

  void selectTopic(Topic? topic) {
    if (state.phase != ExportPhase.idle) return;
    state = state.copyWith(
      subjectId: topic?.subjectId,
      subjectName: topic?.subjectName,
      topicId: topic?.id,
      topicName: topic?.name,
    );
  }

  void clearFilter() {
    if (state.phase != ExportPhase.idle) return;
    state = state.copyWith(
      subjectId: null,
      subjectName: null,
      topicId: null,
      topicName: null,
    );
  }

  Future<void> createExport() async {
    if (state.phase == ExportPhase.submitting ||
        state.phase == ExportPhase.downloading) {
      return;
    }
    state = state.copyWith(phase: ExportPhase.submitting, failure: null);
    try {
      final job = await resolve(ref)
          .create(subjectId: state.subjectId, topicId: state.topicId);
      if (ref.mounted) {
        state = state.copyWith(phase: ExportPhase.result, job: job);
      }
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = state.copyWith(phase: ExportPhase.idle, failure: failure);
      }
    }
  }

  Future<void> download() async {
    final job = state.job;
    if (job == null ||
        job.status != ExportJobStatus.completed ||
        state.phase == ExportPhase.downloading) {
      return;
    }
    if (job.expiredAt(DateTime.now())) {
      state = state.copyWith(
        downloadFailure: const AppFailure(
          FailureKind.notFound,
          code: 'EXPORT_EXPIRED',
        ),
      );
      return;
    }
    state = state.copyWith(
      phase: ExportPhase.downloading,
      downloadFailure: null,
    );
    try {
      final file = await resolve(ref).download(job.id);
      if (!ref.mounted) return;
      final date = job.createdAt.toIso8601String().substring(0, 10);
      await resolve(ref).save(file.bytes, 'hatora-soru-defteri-$date.pdf');
      if (ref.mounted) state = state.copyWith(phase: ExportPhase.result);
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = state.copyWith(
          phase: ExportPhase.result,
          downloadFailure: failure,
        );
      }
    }
  }

  void reset() {
    if (state.phase == ExportPhase.submitting ||
        state.phase == ExportPhase.downloading) {
      return;
    }
    state = state.copyWith(
      phase: ExportPhase.idle,
      job: null,
      failure: null,
      downloadFailure: null,
    );
  }
}
