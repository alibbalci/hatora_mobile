import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../domain/catalog.dart';
import 'catalog_mapper.dart';
import 'catalog_remote_data_source.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this.remote);
  final CatalogRemoteDataSource remote;
  @override
  Future<List<ExamChoice>> examChoices() => repositoryCall(() async {
    final exams = await remote.exams();
    final choices = <ExamChoice>[];
    for (final dto in exams) {
      final exam = mapExam(dto);
      choices.addAll(
        (await remote.editions(exam.id)).map((e) => mapEdition(e, exam)),
      );
    }
    return List.unmodifiable(choices);
  });
  @override
  Future<QuestionCatalog> questionCatalog(
    String examId,
  ) => repositoryCall(() async {
    final exams = await remote.exams();
    final matches = exams.where((e) => e.id == examId);
    if (matches.isEmpty) {
      throw const AppFailure(FailureKind.businessRule, code: 'NO_ACTIVE_EXAM');
    }
    final topics = <Topic>[];
    for (final section in await remote.sections(examId)) {
      for (final subject in await remote.subjects(section.id)) {
        topics.addAll(
          (await remote.topics(subject.id))
              .map((t) => mapTopic(t, subject, section)),
        );
      }
    }
    return QuestionCatalog(mapExam(matches.first), List.unmodifiable(topics));
  });
}
