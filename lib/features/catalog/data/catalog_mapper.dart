import '../domain/catalog.dart';
import 'catalog_dto.dart';

Exam mapExam(ExamDto dto) => Exam(
  id: dto.id,
  name: dto.name,
  code: dto.code,
  answerOptionCount: dto.answerOptionCount,
);
ExamChoice mapEdition(EditionDto dto, Exam exam) => ExamChoice(
  editionId: dto.id,
  exam: exam,
  year: dto.year,
  examDate: dto.examDate,
);
Topic mapTopic(
  CatalogNodeDto topic,
  CatalogNodeDto subject,
  CatalogNodeDto section,
) => Topic(
  id: topic.id,
  name: topic.name,
  subjectId: subject.id,
  subjectName: subject.name,
  sectionId: section.id,
  sectionName: section.name,
);
