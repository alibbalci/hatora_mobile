import 'dart:typed_data';

enum ExportJobStatus { pending, processing, completed, failed }

class ExportJob {
  const ExportJob({
    required this.id,
    required this.status,
    required this.createdAt,
    this.filterSubjectId,
    this.filterTopicId,
    this.completedAt,
    this.expiresAt,
    this.downloadUri,
  });
  final String id;
  final ExportJobStatus status;
  final String? filterSubjectId, filterTopicId;
  final DateTime createdAt;
  final DateTime? completedAt, expiresAt;
  final Uri? downloadUri;
  bool expiredAt(DateTime now) =>
      expiresAt != null && !now.isBefore(expiresAt!);
}

class ExportFile {
  const ExportFile(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String? mimeType;
}

abstract interface class ExportFileOpener {
  Future<void> open(Uint8List bytes, String fileName);
}

class ExportSubjectCount {
  const ExportSubjectCount(this.id, this.name, this.count);
  final String id, name;
  final int count;
}

class ExportOptions {
  const ExportOptions(this.totalCount, this.subjects);
  final int totalCount;
  final List<ExportSubjectCount> subjects;
}
