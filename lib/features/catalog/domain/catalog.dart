import 'exam_schedule.dart';

class Exam {
  const Exam({
    required this.id,
    required this.name,
    required this.code,
    required this.answerOptionCount,
  });
  final String id, name, code;
  final int answerOptionCount;
}

class ExamChoice {
  const ExamChoice({
    required this.editionId,
    required this.exam,
    required this.year,
    this.examDate,
    this.estimatedDate,
  });
  final String editionId;
  final Exam exam;
  final int year;
  final DateTime? examDate, estimatedDate;
  String get label => '${exam.name} · $year';
}

class Topic {
  const Topic({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.subjectName,
    required this.sectionId,
    required this.sectionName,
  });
  final String id, name, subjectId, subjectName, sectionId, sectionName;
  String get groupLabel => '$sectionName · $subjectName';
}

class QuestionCatalog {
  const QuestionCatalog(this.exam, this.topics);
  final Exam exam;
  final List<Topic> topics;
}

abstract interface class CatalogRepository {
  Future<List<ExamChoice>> examChoices();
  Future<QuestionCatalog> questionCatalog(String examId);
  Future<List<ExamSessionSchedule>> examSessions(
    String examId,
    String editionId,
  );
}

class GetExamScheduleUseCase {
  const GetExamScheduleUseCase(this.repository);
  final CatalogRepository repository;
  Future<List<ExamSessionSchedule>> call(String examId, String editionId) =>
      repository.examSessions(examId, editionId);
}

class LoadExamChoicesUseCase {
  const LoadExamChoicesUseCase(this.repository);
  final CatalogRepository repository;
  Future<List<ExamChoice>> call() => repository.examChoices();
}
