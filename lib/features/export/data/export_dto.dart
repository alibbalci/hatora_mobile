class ExportJobDto {
  ExportJobDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      format = json['format'] as String,
      status = json['status'] as String,
      filterSubjectId = json['filterSubjectId'] as String?,
      filterTopicId = json['filterTopicId'] as String?,
      createdAt = json['createdAt'] as String,
      completedAt = json['completedAt'] as String?,
      expiresAt = json['expiresAt'] as String?,
      downloadUri = json['downloadUri'] as String?;
  final String id, format, status, createdAt;
  final String? filterSubjectId,
      filterTopicId,
      completedAt,
      expiresAt,
      downloadUri;
}
