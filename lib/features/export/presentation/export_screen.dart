import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/design/app_bottom_sheet.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widget/components.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/export_models.dart';
import 'export_view_model.dart';

/// TR: Sorularımı PDF'e aktar akışını, tam sayfa yerine tek, tutarlı bir
/// modal sheet olarak açar (spec: "keep PDF export simple").
/// EN: Opens the "export my questions to PDF" flow as one consistent modal
/// sheet instead of a full page (spec: "keep PDF export simple").
Future<void> openExportSheet(BuildContext context) => showAppBottomSheet<void>(
  context: context,
  title: 'PDF oluştur',
  subtitle: 'Sorularını yazdır ya da paylaş',
  icon: Icons.picture_as_pdf_outlined,
  builder: (_) => const ExportSheetBody(),
);

class ExportSheetBody extends ConsumerWidget {
  const ExportSheetBody({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exportViewModelProvider),
        vm = ref.read(exportViewModelProvider.notifier),
        options = ref.watch(exportOptionsProvider);
    final data = options.asData?.value;
    final count = data == null
        ? 0
        : state.subjectId == null
        ? data.totalCount
        : data.subjects
                  .where((s) => s.id == state.subjectId)
                  .firstOrNull
                  ?.count ??
              0;
    final enabled = state.phase == ExportPhase.idle;
    Widget option(String label, int number, String? id, {bool wide = false}) {
      final selected = state.subjectId == id;
      return Material(
        color: selected ? AppColors.primaryInk : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled && number > 0
              ? () =>
                    id == null ? vm.clearFilter() : vm.selectSubject(id, label)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                if (wide) ...[
                  Icon(
                    Icons.layers_outlined,
                    size: 18,
                    color: selected ? AppColors.surface : AppColors.primaryInk,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: number == 0
                          ? AppColors.secondaryText.withValues(alpha: .6)
                          : selected
                          ? AppColors.surface
                          : AppColors.primaryInk,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$number${wide ? ' soru' : ''}',
                  style: TextStyle(
                    color: selected
                        ? AppColors.surface.withValues(alpha: .7)
                        : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Ders seç',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: 12),
        options.when(
          loading: () => const LoadingView(label: 'Dersler yükleniyor…'),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(exportOptionsProvider),
          ),
          data: (data) => Column(
            children: [
              option('Tüm dersler', data.totalCount, null, wide: true),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, c) => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: data.subjects
                      .map(
                        (s) => SizedBox(
                          width: MediaQuery.textScalerOf(context).scale(14) > 18
                              ? c.maxWidth
                              : (c.maxWidth - 10) / 2,
                          child: option(s.name, s.count, s.id),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        if (state.failure != null) ErrorView(error: state.failure!),
        const SizedBox(height: 24),
        if (state.phase != ExportPhase.result &&
            state.phase != ExportPhase.downloading)
          HatoraPrimaryButton(
            label: '$count soruyu PDF yap',
            solidColor: AppColors.accent,
            busy: state.phase == ExportPhase.submitting,
            busyLabel: 'Oluşturuluyor…',
            onPressed: data != null && count > 0 && count <= 300
                ? vm.createExport
                : null,
          ),
        if (count > 300)
          Text(
            'Bir PDF’e en fazla 300 soru ekleyebilirsin. Ders seçerek sayıyı azalt.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (state.job != null &&
            (state.phase == ExportPhase.result ||
                state.phase == ExportPhase.downloading))
          _JobResult(state: state, vm: vm),
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
                        job.expiredAt(DateTime.now())
                            ? 'PDF bağlantısı sona erdi'
                            : 'PDF hazır',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    job.expiredAt(DateTime.now())
                        ? 'Soruların saklanıyor. Paylaşmak için yeni bir PDF oluştur.'
                        : 'Sorularını indirip paylaşabilirsin.',
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
                    onPressed: job.expiredAt(DateTime.now())
                        ? null
                        : vm.download,
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
          onPressed: state.phase == ExportPhase.downloading ? null : vm.reset,
          child: const Text('Yeni dışa aktarma başlat'),
        ),
      ],
    );
  }
}
