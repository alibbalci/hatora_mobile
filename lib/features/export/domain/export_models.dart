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
}

class ExportFile {
  const ExportFile(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String? mimeType;
}

abstract interface class ExportFileOpener {
  Future<void> open(Uint8List bytes, String fileName);
}
