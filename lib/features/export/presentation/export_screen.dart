import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/design/app_bottom_sheet.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widget/components.dart';
import '../../catalog/domain/catalog.dart';
import '../domain/export_models.dart';
import 'export_view_model.dart';

/// TR: Sorularımı PDF'e aktar akışını, tam sayfa yerine tek, tutarlı bir
/// modal sheet olarak açar (spec: "keep PDF export simple").
/// EN: Opens the "export my questions to PDF" flow as one consistent modal
/// sheet instead of a full page (spec: "keep PDF export simple").
Future<void> openExportSheet(BuildContext context) => showAppBottomSheet<void>(
  context: context,
  title: 'PDF Oluştur',
  builder: (_) => const ExportSheetBody(),
);

class ExportSheetBody extends ConsumerWidget {
  const ExportSheetBody({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exportViewModelProvider);
    final vm = ref.read(exportViewModelProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        state.catalog.when(
          loading: () => const LoadingView(label: 'Konu listesi yükleniyor…'),
          error: (error, _) => ErrorView(error: error, onRetry: vm.load),
          data: (catalog) =>
              _FilterPicker(state: state, vm: vm, catalog: catalog),
        ),
        if (state.failure != null) ErrorView(error: state.failure!),
        if (state.phase != ExportPhase.result)
          HatoraPrimaryButton(
            label: 'PDF Oluştur',
            busy: state.phase == ExportPhase.submitting,
            busyLabel: 'Oluşturuluyor…',
            onPressed: state.catalog.hasValue ? vm.createExport : null,
          ),
        if (state.phase == ExportPhase.result && state.job != null)
          _JobResult(state: state, vm: vm),
      ],
    );
  }
}

class _FilterPicker extends StatelessWidget {
  const _FilterPicker({
    required this.state,
    required this.vm,
    required this.catalog,
  });
  final ExportState state;
  final ExportViewModel vm;
  final QuestionCatalog catalog;
  @override
  Widget build(BuildContext context) {
    final subjects = <String, String>{};
    for (final topic in catalog.topics) {
      subjects.putIfAbsent(topic.subjectId, () => topic.subjectName);
    }
    final enabled = state.phase == ExportPhase.idle;
    final topicsForSubject = state.subjectId == null
        ? const <Topic>[]
        : catalog.topics.where((t) => t.subjectId == state.subjectId).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktif sınavındaki tüm sorularını dışa aktarabilir ya da ders/konuya göre filtreleyebilirsin.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SectionHeader('Ders'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('Tüm dersler'),
              selected: state.subjectId == null,
              onSelected: enabled ? (_) => vm.clearFilter() : null,
            ),
            for (final entry in subjects.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: state.subjectId == entry.key,
                onSelected: enabled
                    ? (_) => vm.selectSubject(entry.key, entry.value)
                    : null,
              ),
          ],
        ),
        if (state.subjectId != null) ...[
          const SectionHeader('Konu'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: Text('Tüm ${state.subjectName} konuları'),
                selected: state.topicId == null,
                onSelected: enabled
                    ? (_) =>
                          vm.selectSubject(state.subjectId, state.subjectName)
                    : null,
              ),
              for (final topic in topicsForSubject)
                ChoiceChip(
                  label: Text(topic.name),
                  selected: state.topicId == topic.id,
                  onSelected: enabled ? (_) => vm.selectTopic(topic) : null,
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.base),
      ],
    );
  }
}

class _JobResult extends StatelessWidget {
  const _JobResult({required this.state, required this.vm});
  final ExportState state;
  final ExportViewModel vm;
  @override
  Widget build(BuildContext context) {
    final job = state.job!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        switch (job.status) {
          ExportJobStatus.completed => Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'PDF hazır',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sorularını indirip paylaşabilirsin.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (state.downloadFailure != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: ErrorView(error: state.downloadFailure!),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  HatoraPrimaryButton(
                    label: 'PDF\'yi Aç / Paylaş',
                    busy: state.phase == ExportPhase.downloading,
                    onPressed: vm.download,
                  ),
                ],
              ),
            ),
          ),
          ExportJobStatus.failed => const EmptyView(
            icon: Icons.error_outline,
            title: 'PDF oluşturulamadı',
            message: 'Bir sorun oluştu. Lütfen tekrar dene.',
          ),
          ExportJobStatus.pending ||
          ExportJobStatus.processing => const EmptyView(
            icon: Icons.hourglass_top_outlined,
            title: 'Hazırlanıyor',
            message: 'PDF birazdan hazır olacak.',
          ),
        },
        TextButton(
          onPressed: vm.reset,
          child: const Text('Yeni dışa aktarma başlat'),
        ),
      ],
    );
  }
}
