class ExamSessionSchedule {
  const ExamSessionSchedule({
    required this.code,
    required this.name,
    this.examDate,
    this.estimatedDate,
    this.sourceUri,
  });
  final String code, name;
  final DateTime? examDate, estimatedDate;
  final Uri? sourceUri;
}

typedef ExamScheduleKey = ({String examId, String editionId});
