import '../../../core/error/failure_mapper.dart';
import '../domain/question.dart';
import 'question_mapper.dart';
import 'question_remote_data_source.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  QuestionRepositoryImpl(this.remote);
  final QuestionRemoteDataSource remote;
  @override
  Future<QuestionAnalysis> analyze(SelectedImage image) =>
      repositoryCall(() async => mapAnalysis(await remote.analyze(image)));
  @override
  Future<Question> create(QuestionDraft draft) =>
      repositoryCall(() async => mapQuestion(await remote.create(draft)));
  @override
  Future<QuestionPage> getQuestions({
    int page = 0,
    int size = 20,
    QuestionFilters filters = const QuestionFilters(),
  }) => repositoryCall(
    () async => mapQuestionPage(
      await remote.getQuestions(page: page, size: size, filters: filters),
    ),
  );
  @override
  Future<Question> getQuestion(String id) =>
      repositoryCall(() async => mapQuestion(await remote.getQuestion(id)));
  @override
  Future<Question> updateQuestion(String id, QuestionUpdate update) =>
      repositoryCall(
        () async => mapQuestion(await remote.updateQuestion(id, update)),
      );
  @override
  Future<void> archiveQuestion(String id) =>
      repositoryCall(() => remote.archiveQuestion(id));
  @override
  Future<QuestionImage> loadImage(Uri uri) =>
      repositoryCall(() => remote.image(uri));
}
