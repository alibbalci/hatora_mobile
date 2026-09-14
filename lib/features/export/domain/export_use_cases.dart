import 'dart:typed_data';

import 'export_models.dart';
import 'export_repository.dart';

class CreateExportUseCase {
  const CreateExportUseCase(this.repository);
  final ExportRepository repository;
  Future<ExportJob> call({String? subjectId, String? topicId}) =>
      repository.createExport(subjectId: subjectId, topicId: topicId);
}

class GetExportUseCase {
  const GetExportUseCase(this.repository);
  final ExportRepository repository;
  Future<ExportJob> call(String id) => repository.getExport(id);
}

class DownloadExportUseCase {
  const DownloadExportUseCase(this.repository);
  final ExportRepository repository;
  Future<ExportFile> call(String id) => repository.download(id);
}

class SaveExportFileUseCase {
  const SaveExportFileUseCase(this.opener);
  final ExportFileOpener opener;
  Future<void> call(Uint8List bytes, String fileName) =>
      opener.open(bytes, fileName);
}
