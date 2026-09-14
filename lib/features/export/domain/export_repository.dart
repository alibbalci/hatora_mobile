import 'export_models.dart';

abstract interface class ExportRepository {
  Future<ExportJob> createExport({String? subjectId, String? topicId});
  Future<ExportJob> getExport(String id);
  Future<ExportFile> download(String id);
}
