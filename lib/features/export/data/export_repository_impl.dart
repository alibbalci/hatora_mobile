import '../../../core/error/failure_mapper.dart';
import '../domain/export_models.dart';
import '../domain/export_repository.dart';
import 'export_mapper.dart';
import 'export_remote_data_source.dart';

class ExportRepositoryImpl implements ExportRepository {
  const ExportRepositoryImpl(this.remote);
  final ExportRemoteDataSource remote;

  @override
  Future<ExportJob> createExport({String? subjectId, String? topicId}) =>
      repositoryCall(
        () async => mapExportJob(
          await remote.create(subjectId: subjectId, topicId: topicId),
        ),
      );

  @override
  Future<ExportJob> getExport(String id) =>
      repositoryCall(() async => mapExportJob(await remote.get(id)));

  @override
  Future<ExportFile> download(String id) =>
      repositoryCall(() => remote.download(id));
}
