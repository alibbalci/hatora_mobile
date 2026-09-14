import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatora_mobile/app/providers.dart';
import 'package:hatora_mobile/core/error/app_failure.dart';
import 'package:hatora_mobile/core/theme/app_theme.dart';
import 'package:hatora_mobile/features/export/data/export_dto.dart';
import 'package:hatora_mobile/features/export/data/export_mapper.dart';
import 'package:hatora_mobile/features/export/data/export_remote_data_source.dart';
import 'package:hatora_mobile/features/export/data/export_repository_impl.dart';
import 'package:hatora_mobile/features/export/domain/export_models.dart';
import 'package:hatora_mobile/features/export/presentation/export_screen.dart';
import 'package:hatora_mobile/features/export/presentation/export_view_model.dart';

import 'support/fakes.dart';

Map<String, dynamic> jobJson({
  String status = 'COMPLETED',
  String? downloadUri = '/api/exports/e1/download',
  String? subjectId,
  String? topicId,
}) => {
  'id': 'e1',
  'format': 'PDF',
  'status': status,
  'filterSubjectId': subjectId,
  'filterTopicId': topicId,
  'createdAt': '2026-09-13T10:00:00Z',
  'completedAt': status == 'COMPLETED' ? '2026-09-13T10:00:05Z' : null,
  'expiresAt': status == 'COMPLETED' ? '2026-09-20T10:00:05Z' : null,
  'downloadUri': downloadUri,
};

class ThrowingExportRemote extends ExportRemoteDataSource {
  ThrowingExportRemote(this.error) : super(Dio());
  final Object error;
  @override
  Future<ExportJobDto> create({String? subjectId, String? topicId}) async =>
      throw error;
  @override
  Future<ExportJobDto> get(String id) async => throw error;
}

void main() {
  test('COMPLETED job maps downloadUri', () {
    final job = mapExportJob(ExportJobDto.fromJson(jobJson()));
    expect(job.status, ExportJobStatus.completed);
    expect(job.downloadUri, Uri.parse('/api/exports/e1/download'));
  });

  test('FAILED job maps with a null downloadUri', () {
    final job = mapExportJob(
      ExportJobDto.fromJson(jobJson(status: 'FAILED', downloadUri: null)),
    );
    expect(job.status, ExportJobStatus.failed);
    expect(job.downloadUri, isNull);
  });

  test(
    'PROCESSING/PENDING statuses map without inventing a terminal state',
    () {
      expect(
        mapExportJob(
          ExportJobDto.fromJson(
            jobJson(status: 'PROCESSING', downloadUri: null),
          ),
        ).status,
        ExportJobStatus.processing,
      );
      expect(
        mapExportJob(
          ExportJobDto.fromJson(jobJson(status: 'PENDING', downloadUri: null)),
        ).status,
        ExportJobStatus.pending,
      );
    },
  );

  test(
    'repository normalizes EXPORT_EMPTY/EXPORT_TOO_LARGE/EXPORT_NOT_READY',
    () async {
      Future<void> expectCode(int status, String code, FailureKind kind) async {
        final error = DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: status,
            data: {'code': code},
          ),
        );
        await expectLater(
          ExportRepositoryImpl(ThrowingExportRemote(error)).createExport(),
          throwsA(
            isA<AppFailure>()
                .having((e) => e.kind, 'kind', kind)
                .having((e) => e.code, 'code', code)
                .having((e) => e.message, 'message', isNot(contains('_'))),
          ),
        );
      }

      await expectCode(422, 'EXPORT_EMPTY', FailureKind.businessRule);
      await expectCode(422, 'EXPORT_TOO_LARGE', FailureKind.businessRule);
      await expectCode(422, 'NO_ACTIVE_EXAM', FailureKind.businessRule);
    },
  );

  test('EXPORT_NOT_READY (409) normalizes as a conflict', () async {
    final error = DioException(
      requestOptions: RequestOptions(),
      response: Response(
        requestOptions: RequestOptions(),
        statusCode: 409,
        data: {'code': 'EXPORT_NOT_READY'},
      ),
    );
    await expectLater(
      ExportRepositoryImpl(ThrowingExportRemote(error)).getExport('e1'),
      throwsA(
        isA<AppFailure>().having((e) => e.kind, 'kind', FailureKind.conflict),
      ),
    );
  });

  ProviderContainer container({
    required FakeExportRepository repo,
    required FakeExportFileOpener opener,
  }) => ProviderContainer(
    overrides: [
      exportRepositoryProvider.overrideWithValue(repo),
      exportFileOpenerProvider.overrideWithValue(opener),
      onboardingRepositoryProvider.overrideWithValue(
        FakeOnboardingRepository(),
      ),
      catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
    ],
  );

  test('create export success renders result and stores job as-is', () async {
    final repo = FakeExportRepository();
    final opener = FakeExportFileOpener();
    final c = container(repo: repo, opener: opener);
    addTearDown(c.dispose);
    c.read(exportViewModelProvider);
    await flush();
    await flush();
    await c.read(exportViewModelProvider.notifier).createExport();
    final state = c.read(exportViewModelProvider);
    expect(state.phase, ExportPhase.result);
    expect(state.job?.status, ExportJobStatus.completed);
    expect(repo.createCalls, 1);
  });

  test('backend FAILED job (HTTP 201) is rendered as failed, not as an app failure', () async {
    final repo = FakeExportRepository()
      ..job = ExportJob(
        id: 'e2',
        status: ExportJobStatus.failed,
        createdAt: DateTime.utc(2026, 9, 13),
      );
    final opener = FakeExportFileOpener();
    final c = container(repo: repo, opener: opener);
    addTearDown(c.dispose);
    c.read(exportViewModelProvider);
    await flush();
    await flush();
    await c.read(exportViewModelProvider.notifier).createExport();
    final state = c.read(exportViewModelProvider);
    expect(state.phase, ExportPhase.result);
    expect(state.job?.status, ExportJobStatus.failed);
    expect(state.failure, isNull);
  });

  test('EXPORT_EMPTY create failure keeps filter selection and shows a friendly state', () async {
    final repo = FakeExportRepository()
      ..createFailure = const AppFailure(
        FailureKind.businessRule,
        code: 'EXPORT_EMPTY',
      );
    final opener = FakeExportFileOpener();
    final c = container(repo: repo, opener: opener);
    addTearDown(c.dispose);
    c.read(exportViewModelProvider);
    await flush();
    await flush();
    c
        .read(exportViewModelProvider.notifier)
        .selectSubject(topic.subjectId, topic.subjectName);
    await c.read(exportViewModelProvider.notifier).createExport();
    final state = c.read(exportViewModelProvider);
    expect(state.phase, ExportPhase.idle);
    expect(state.failure?.code, 'EXPORT_EMPTY');
    expect(
      state.failure?.message,
      'Bu filtreye uygun dışa aktarılacak soru bulunamadı.',
    );
    expect(state.subjectId, topic.subjectId);
  });

  test(
    'EXPORT_TOO_LARGE shows the friendly narrow-the-filter message',
    () async {
      final repo = FakeExportRepository()
        ..createFailure = const AppFailure(
          FailureKind.businessRule,
          code: 'EXPORT_TOO_LARGE',
        );
      final c = container(repo: repo, opener: FakeExportFileOpener());
      addTearDown(c.dispose);
      c.read(exportViewModelProvider);
      await flush();
      await flush();
      await c.read(exportViewModelProvider.notifier).createExport();
      expect(
        c.read(exportViewModelProvider).failure?.message,
        'Tek seferde çok fazla soru seçildi. Filtreyi daraltıp tekrar deneyin.',
      );
    },
  );

  test(
    'download saves bytes through the platform opener with a friendly filename',
    () async {
      final repo = FakeExportRepository();
      final opener = FakeExportFileOpener();
      final c = container(repo: repo, opener: opener);
      addTearDown(c.dispose);
      c.read(exportViewModelProvider);
      await flush();
      await flush();
      await c.read(exportViewModelProvider.notifier).createExport();
      await c.read(exportViewModelProvider.notifier).download();
      expect(opener.openCalls, 1);
      expect(opener.lastFileName, startsWith('hatora-soru-defteri'));
      expect(opener.lastFileName, endsWith('.pdf'));
      expect(c.read(exportViewModelProvider).downloadFailure, isNull);
    },
  );

  test(
    'download not ready (409) surfaces as a download failure, not a crash',
    () async {
      final repo = FakeExportRepository()
        ..downloadFailure = const AppFailure(
          FailureKind.conflict,
          code: 'EXPORT_NOT_READY',
        );
      final c = container(repo: repo, opener: FakeExportFileOpener());
      addTearDown(c.dispose);
      c.read(exportViewModelProvider);
      await flush();
      await flush();
      await c.read(exportViewModelProvider.notifier).createExport();
      await c.read(exportViewModelProvider.notifier).download();
      final state = c.read(exportViewModelProvider);
      expect(state.phase, ExportPhase.result);
      expect(state.downloadFailure?.code, 'EXPORT_NOT_READY');
    },
  );

  testWidgets(
    'backend returns COMPLETED: create then the download action is enabled',
    (tester) async {
      final repo = FakeExportRepository();
      final c = container(repo: repo, opener: FakeExportFileOpener());
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(body: const ExportSheetBody()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('PDF hazır'), findsOneWidget);
      expect(find.text("PDF'yi Aç / Paylaş"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'backend returns FAILED job with HTTP 201: UI shows failed, never a download-ready state',
    (tester) async {
      final repo = FakeExportRepository()
        ..job = ExportJob(
          id: 'e2',
          status: ExportJobStatus.failed,
          createdAt: DateTime.utc(2026, 9, 13),
        );
      final c = container(repo: repo, opener: FakeExportFileOpener());
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(body: const ExportSheetBody()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('PDF oluşturulamadı'), findsOneWidget);
      expect(find.text("PDF'yi Aç / Paylaş"), findsNothing);
      expect(find.text('PDF hazır'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty selection (EXPORT_EMPTY) shows the friendly message, not a raw error',
    (tester) async {
      final repo = FakeExportRepository()
        ..createFailure = const AppFailure(
          FailureKind.businessRule,
          code: 'EXPORT_EMPTY',
        );
      final c = container(repo: repo, opener: FakeExportFileOpener());
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(body: const ExportSheetBody()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(
        find.text('Bu filtreye uygun dışa aktarılacak soru bulunamadı.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
