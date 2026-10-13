import '../../../core/error/app_failure.dart';
import '../../catalog/domain/catalog.dart';
import '../../onboarding/domain/onboarding.dart';
import 'question.dart';

class PickQuestionImageUseCase {
  const PickQuestionImageUseCase(this.picker);
  final ImagePickerService picker;
  Future<SelectedImage?> call(ImageOrigin origin) => picker.pick(origin);
  Future<SelectedImage?> recover() => picker.recover();
}

class AnalyzeQuestionUseCase {
  const AnalyzeQuestionUseCase(this.repository);
  final QuestionRepository repository;
  Future<QuestionAnalysis> call(SelectedImage image) =>
      repository.analyze(image);
}

class CreateQuestionUseCase {
  const CreateQuestionUseCase(this.repository);
  final QuestionRepository repository;
  Future<Question> call(QuestionDraft draft) => repository.create(draft);
}

class GetQuestionsUseCase {
  const GetQuestionsUseCase(this.repository);
  final QuestionRepository repository;
  Future<QuestionPage> call({
    int page = 0,
    int size = 20,
    QuestionFilters filters = const QuestionFilters(),
  }) => repository.getQuestions(page: page, size: size, filters: filters);
}

class GetQuestionDetailUseCase {
  const GetQuestionDetailUseCase(this.repository);
  final QuestionRepository repository;
  Future<Question> call(String id) => repository.getQuestion(id);
}

class UpdateQuestionUseCase {
  const UpdateQuestionUseCase(this.repository);
  final QuestionRepository repository;
  Future<Question> call(String id, QuestionUpdate update) =>
      repository.updateQuestion(id, update);
}

class ArchiveQuestionUseCase {
  const ArchiveQuestionUseCase(this.repository);
  final QuestionRepository repository;
  Future<void> call(String id) => repository.archiveQuestion(id);
}

class LoadQuestionCatalogUseCase {
  const LoadQuestionCatalogUseCase(this.onboarding, this.catalog);
  final OnboardingRepository onboarding;
  final CatalogRepository catalog;
  Future<QuestionCatalog> call({String? examId}) async {
    if (examId != null && examId.isNotEmpty) {
      return catalog.questionCatalog(examId);
    }
    final status = await onboarding.status();
    final activeExamId = status.examId;
    if (activeExamId == null) {
      throw const AppFailure(FailureKind.businessRule, code: 'NO_ACTIVE_EXAM');
    }
    return catalog.questionCatalog(activeExamId);
  }
}
