import '../../../core/error/app_failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/error/failure_mapper.dart';
import '../domain/catalog.dart';
import '../domain/exam_schedule.dart';
import 'catalog_mapper.dart';
import 'catalog_dto.dart';
import 'catalog_remote_data_source.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this.remote);
  final CatalogRemoteDataSource remote;
  @override
  Future<List<ExamSessionSchedule>> examSessions(
    String examId,
    String editionId,
  ) => repositoryCall(() async {
    final values = await remote.sessions(examId, editionId);
    final editions = await remote.editions(examId);
    final current = editions.where((e) => e.id == editionId).firstOrNull;
    final previous = editions.where((e) => current != null && e.year < current.year).toList()..sort((a,b) => b.year.compareTo(a.year));
    final earlierSessions = values.any((s) => s.examDate == null) && previous.isNotEmpty ? await remote.sessions(examId, previous.first.id) : const <ExamSessionDto>[];
    return List.unmodifiable(
      values.where((v) => !isPastExam(v.examDate, current?.year ?? DateTime.now().year)).map(
        (value) => ExamSessionSchedule(
          code: value.code,
          name: value.name,
          examDate: value.examDate,
          estimatedDate: current == null ? null : estimateExamMonth(current.year, earlierSessions.where((s) => s.code == value.code && s.examDate != null).map<DateTime>((s) => s.examDate as DateTime)),
          sourceUri: value.sourceUrl == null
              ? null
              : Uri.tryParse(value.sourceUrl!),
        ),
      ),
    );
  });

  @override
  Future<List<ExamChoice>> examChoices() => repositoryCall(() async {
    final exams = await remote.exams();
    final choices = <ExamChoice>[];
    for (final dto in exams) {
      final exam = mapExam(dto);
      final editions = await remote.editions(exam.id);
      choices.addAll(editions.where((e) => !isPastExam(e.examDate, e.year)).map((e) => ExamChoice(editionId: e.id, exam: exam, year: e.year, examDate: e.examDate, estimatedDate: estimateExamMonth(e.year, editions.map((v) => v.examDate).whereType<DateTime>()))));
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
