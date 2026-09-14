class ExamDto {
  ExamDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      code = json['code'] as String,
      answerOptionCount = json['answerOptionCount'] as int;
  final String id, name, code;
  final int answerOptionCount;
}

class EditionDto {
  EditionDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      year = json['year'] as int,
      examDate = json['examDate'] == null
          ? null
          : DateTime.parse(json['examDate'] as String);
  final String id;
  final int year;
  final DateTime? examDate;
}

// TR: Üç katalog düzeyi bu akışta yalnızca kimlik ve ad gerektirir.
// EN: The three hierarchy levels need only identity and name in this flow.
class CatalogNodeDto {
  CatalogNodeDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String;
  final String id, name;
}
