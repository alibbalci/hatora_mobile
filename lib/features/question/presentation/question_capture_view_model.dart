import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../domain/question.dart';
import '../domain/question_use_cases.dart';

enum CapturePhase {
  idle,
  selecting,
  imageSelected,
  analyzing,
  analysisSuccess,
  analysisFailure,
}

class CaptureState {
  const CaptureState({
    this.phase = CapturePhase.idle,
    this.image,
    this.analysis,
    this.failure,
  });
  final CapturePhase phase;
  final SelectedImage? image;
  final QuestionAnalysis? analysis;
  final AppFailure? failure;
  bool get busy =>
      phase == CapturePhase.selecting || phase == CapturePhase.analyzing;
  bool get canContinue =>
      image != null &&
      analysis != null &&
      (analysis!.status == AnalysisStatus.completed ||
          analysis!.status == AnalysisStatus.failed);
  ConfirmationSeed? get seed =>
      canContinue ? ConfirmationSeed(analysis!, image!) : null;
}

class QuestionCaptureViewModel extends Notifier<CaptureState> {
  QuestionCaptureViewModel(this.resolve);
  final ({PickQuestionImageUseCase pick, AnalyzeQuestionUseCase analyze})
  Function(Ref)
  resolve;
  int _operation = 0;
  @override
  CaptureState build() {
    Future.microtask(recover);
    return const CaptureState();
  }

  Future<void> recover() async {
    try {
      final image = await resolve(ref).pick.recover();
      if (ref.mounted && state.phase == CapturePhase.idle && image != null) {
        state = CaptureState(phase: CapturePhase.imageSelected, image: image);
      }
    } on AppFailure catch (failure) {
      if (ref.mounted && state.phase == CapturePhase.idle) {
        state = CaptureState(failure: failure);
      }
    }
  }

  Future<void> selectImage(ImageOrigin origin) async {
    if (state.busy) return;
    final previous = state;
    state = CaptureState(phase: CapturePhase.selecting, image: previous.image);
    try {
      final image = await resolve(ref).pick(origin);
      if (ref.mounted) {
        state = image == null
            ? previous
            : CaptureState(phase: CapturePhase.imageSelected, image: image);
      }
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = CaptureState(
          phase: previous.phase,
          image: previous.image,
          analysis: previous.analysis,
          failure: failure,
        );
      }
    }
  }

  Future<void> analyze() async {
    final image = state.image;
    if (state.busy || image == null) return;
    final operation = ++_operation;
    state = CaptureState(phase: CapturePhase.analyzing, image: image);
    try {
      final analysis = await resolve(ref).analyze(image);
      if (ref.mounted && operation == _operation) {
        state = CaptureState(
          image: image,
          analysis: analysis,
          phase: analysis.status == AnalysisStatus.failed
              ? CapturePhase.analysisFailure
              : CapturePhase.analysisSuccess,
        );
      }
    } on AppFailure catch (failure) {
      // TR: Yükleme hatasında analiz kimliği yoktur; manuel kayıt uydurulmaz.
      // EN: A failed upload has no analysis id; never fabricate a manual record.
      if (ref.mounted && operation == _operation) {
        state = CaptureState(
          phase: CapturePhase.analysisFailure,
          image: image,
          failure: failure,
        );
      }
    }
  }

  void cancelAnalysis() {
    if (state.phase != CapturePhase.analyzing) return;
    _operation++;
    state = CaptureState(phase: CapturePhase.imageSelected, image: state.image);
  }

  void reset() {
    if (!state.busy) state = const CaptureState();
  }
}
