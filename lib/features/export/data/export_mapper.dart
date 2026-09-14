import '../domain/export_models.dart';
import 'export_dto.dart';

ExportJobStatus _status(String value) => switch (value) {
  'PENDING' => ExportJobStatus.pending,
  'PROCESSING' => ExportJobStatus.processing,
  'COMPLETED' => ExportJobStatus.completed,
  'FAILED' => ExportJobStatus.failed,
  _ => ExportJobStatus.failed,
};

ExportJob mapExportJob(ExportJobDto d) => ExportJob(
  id: d.id,
  status: _status(d.status),
  filterSubjectId: d.filterSubjectId,
  filterTopicId: d.filterTopicId,
  createdAt: DateTime.parse(d.createdAt),
  completedAt: d.completedAt == null ? null : DateTime.parse(d.completedAt!),
  expiresAt: d.expiresAt == null ? null : DateTime.parse(d.expiresAt!),
  downloadUri: d.downloadUri == null ? null : Uri.parse(d.downloadUri!),
);
