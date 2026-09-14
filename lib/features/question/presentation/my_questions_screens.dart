import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../catalog/domain/catalog.dart';
import '../../export/presentation/export_screen.dart';
import '../domain/question.dart';
import 'my_questions_view_model.dart';
import 'question_detail_view_model.dart';
import 'question_screens.dart' show difficultyLabels, reasonLabels;

class MyQuestionsScreen extends ConsumerWidget {
  const MyQuestionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myQuestionsViewModelProvider);
    final vm = ref.read(myQuestionsViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorularım'),
        actions: [
          PopupMenuButton<QuestionStatus?>(
            tooltip: 'Duruma göre filtrele',
            icon: const Icon(Icons.filter_alt_outlined),
            onSelected: (status) => vm.setFilters(
              QuestionFilters(
                status: status,
                difficulty: state.filters.difficulty,
              ),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('Tüm aktif sorular')),
              PopupMenuItem(value: QuestionStatus.active, child: Text('Aktif')),
              PopupMenuItem(
                value: QuestionStatus.mastered,
                child: Text('Öğrenilenler'),
              ),
              PopupMenuItem(
                value: QuestionStatus.archived,
                child: Text('Arşivlenenler'),
              ),
            ],
          ),
          PopupMenuButton<Difficulty?>(
            tooltip: 'Zorluğa göre filtrele',
            icon: const Icon(Icons.tune),
            onSelected: (difficulty) => vm.setFilters(
              QuestionFilters(
                status: state.filters.status,
                difficulty: difficulty,
              ),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('Tüm zorluklar')),
              PopupMenuItem(value: Difficulty.hard, child: Text('Zor')),
              PopupMenuItem(value: Difficulty.medium, child: Text('Orta')),
              PopupMenuItem(value: Difficulty.easy, child: Text('Kolay')),
            ],
          ),
          IconButton(
            onPressed: () => openExportSheet(context),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'PDF Oluştur',
          ),
          IconButton(
            onPressed: vm.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.capture).then((_) => vm.refresh()),
        icon: const Icon(Icons.add),
        label: const Text('Soru ekle'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.refresh,
          child: _body(context, ref, state, vm),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    MyQuestionsState state,
    MyQuestionsViewModel vm,
  ) {
    if (state.phase == MyQuestionsPhase.initialLoading) {
      return ListView(
        children: const [LoadingView(label: 'Soruların yükleniyor…')],
      );
    }
    if (state.items.isEmpty && state.phase == MyQuestionsPhase.error) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [ErrorView(error: state.failure!, onRetry: vm.retry)],
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const EmptyView(
            title: 'Henüz soru eklemedin',
            message: 'Kaydettiğin sorular, tekrar tarihini beklemeden burada görünür.',
          ),
          const SizedBox(height: AppSpacing.base),
          HatoraPrimaryButton(
            label: 'İlk sorunu ekle',
            onPressed: () =>
                context.push(Routes.capture).then((_) => vm.refresh()),
          ),
        ],
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 300) vm.loadMore();
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.sm,
          AppSpacing.base,
          100,
        ),
        itemCount: state.items.length + 1,
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return state.phase == MyQuestionsPhase.loadingMore
                ? const LoadingView()
                : state.phase == MyQuestionsPhase.error
                ? ErrorView(error: state.failure!, onRetry: vm.retry)
                : const SizedBox.shrink();
          }
          return QuestionSummaryCard(
            question: state.items[index],
            onTap: () => context
                .push(Routes.questionDetail(state.items[index].id))
                .then((_) => vm.refresh()),
          );
        },
      ),
    );
  }
}

class QuestionSummaryCard extends ConsumerWidget {
  const QuestionSummaryCard({
    super.key,
    required this.question,
    required this.onTap,
  });
  final QuestionSummary question;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: SizedBox(
                width: 84,
                height: 84,
                child: QuestionNetworkImage(uri: question.imageUri),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.subjectName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    question.topicName,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Chip(label: Text(difficultyLabels[question.difficulty]!)),
                      QuestionStatusChip(question: question),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// TR: Soru durumunu tek bakışta gösterir — renk tek başına anlam taşımaz,
/// ikon ve metin her zaman birlikte bulunur.
/// EN: Surfaces question status at a glance — color is never the only
/// signal, an icon and label always accompany it.
class QuestionStatusChip extends StatelessWidget {
  const QuestionStatusChip({super.key, required this.question});
  final QuestionSummary question;
  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (question.status) {
      QuestionStatus.mastered => (
        Icons.emoji_events_outlined,
        AppColors.success,
        'Öğrenildi',
      ),
      QuestionStatus.archived => (
        Icons.inventory_2_outlined,
        AppColors.secondaryText,
        'Arşivlendi',
      ),
      _ => (
        Icons.event_outlined,
        AppColors.accent,
        question.nextReviewDate == null
            ? 'Tekrar tarihi yok'
            : 'Tekrar: ${friendlyDate(question.nextReviewDate!)}',
      ),
    };
    return Chip(
      avatar: Icon(icon, size: 15, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide(color: color.withValues(alpha: 0.28)),
    );
  }
}

class QuestionNetworkImage extends ConsumerWidget {
  const QuestionNetworkImage({super.key, required this.uri});
  final Uri? uri;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (uri == null) {
      return const ColoredBox(
        color: AppColors.surfaceMuted,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.secondaryText,
        ),
      );
    }
    final image = ref.watch(questionImageProvider(uri!));
    return image.when(
      data: (v) => Image.memory(
        v.bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: AppColors.surfaceMuted,
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.secondaryText,
          ),
        ),
      ),
      loading: () => const ColoredBox(
        color: AppColors.surfaceMuted,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const ColoredBox(
        color: AppColors.surfaceMuted,
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}

class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = questionDetailViewModelProvider(id),
        state = ref.watch(p),
        vm = ref.read(p.notifier);
    ref.listen(p, (a, b) {
      if (b.phase == QuestionDetailPhase.archived) {
        ref.invalidate(dashboardViewModelProvider);
        context.pop(true);
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soru detayı'),
        actions: [
          if (state.question != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Düzenle',
              onPressed: () =>
                  context.push(Routes.questionEdit(id)).then((_) => vm.load()),
            ),
        ],
      ),
      body: _detailBody(context, state, vm),
    );
  }

  Widget _detailBody(
    BuildContext context,
    QuestionDetailState state,
    QuestionDetailViewModel vm,
  ) {
    if (state.phase == QuestionDetailPhase.loading) return const LoadingView();
    if (state.question == null) {
      return PageBody(
        children: [ErrorView(error: state.failure!, onRetry: vm.load)],
      );
    }
    final q = state.question!;
    return PageBody(
      children: [
        ClipRRect(
          borderRadius: AppRadius.lgAll,
          child: SizedBox(
            height: 260,
            width: double.infinity,
            child: QuestionNetworkImage(uri: q.imageUri),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.subjectName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    q.topicName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            _StatusBadge(question: q),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        _DetailCard(
          rows: [
            _DetailRow('Doğru cevap', q.correctAnswer),
            _DetailRow('Zorluk', difficultyLabels[q.difficulty]!),
            _DetailRow('Hata nedeni', reasonLabels[q.mistakeReason]!),
          ],
        ),
        if (q.shortNote.isNotEmpty || q.source.isNotEmpty)
          _DetailCard(
            rows: [
              if (q.shortNote.isNotEmpty) _DetailRow('Kısa not', q.shortNote),
              if (q.source.isNotEmpty) _DetailRow('Kaynak', q.source),
            ],
          ),
        _DetailCard(rows: [_DetailRow('Tekrar durumu', _reviewLabelDetail(q))]),
        if (q.solutionImages.isNotEmpty) ...[
          const SectionHeader('Çözüm görselleri'),
          ...q.solutionImages.map(
            (i) => ClipRRect(
              borderRadius: AppRadius.lgAll,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: QuestionNetworkImage(uri: i.imageUri),
                ),
              ),
            ),
          ),
        ],
        if (state.failure != null) ErrorView(error: state.failure!),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: state.phase == QuestionDetailPhase.archiving
              ? null
              : () => _archive(context, vm),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          icon: const Icon(Icons.archive_outlined),
          label: Text(
            state.phase == QuestionDetailPhase.archiving
                ? 'Arşivleniyor…'
                : 'Soruyu arşivle',
          ),
        ),
      ],
    );
  }

  Future<void> _archive(
    BuildContext context,
    QuestionDetailViewModel vm,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Soruyu arşivle?'),
        content: const Text(
          'Bu soru aktif sorulardan ve gelecekteki tekrarlardan kaldırılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Arşivle'),
          ),
        ],
      ),
    );
    if (ok == true) await vm.archive();
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.question});
  final Question question;
  @override
  Widget build(BuildContext context) {
    final mastered = question.status == QuestionStatus.mastered;
    final archived = question.status == QuestionStatus.archived;
    final color = mastered
        ? AppColors.success
        : archived
        ? AppColors.secondaryText
        : AppColors.accent;
    final label = mastered
        ? 'Öğrenildi'
        : archived
        ? 'Arşivlendi'
        : 'Aktif';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.rows});
  final List<_DetailRow> rows;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(height: 1),
              ),
            Text(rows[i].label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(rows[i].value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    ),
  );
}

class _DetailRow {
  const _DetailRow(this.label, this.value);
  final String label, value;
}

class QuestionEditScreen extends ConsumerWidget {
  const QuestionEditScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = questionEditViewModelProvider(id),
        s = ref.watch(p),
        vm = ref.read(p.notifier);
    ref.listen(p, (a, b) {
      if (a?.saved == null && b.saved != null) context.pop(b.saved);
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Soruyu düzenle')),
      body: s.loading
          ? const LoadingView()
          : s.question == null
          ? PageBody(
              children: [ErrorView(error: s.failure!, onRetry: vm.load)],
            )
          : PageBody(
              children: [
                const SectionHeader('Ders ve konu'),
                OutlinedButton.icon(
                  onPressed: s.topics.isEmpty
                      ? null
                      : () async {
                          final topic = await context.push<Topic>(
                            Routes.topics,
                            extra: s.topics,
                          );
                          if (topic != null) vm.topic(topic);
                        },
                  icon: const Icon(Icons.search),
                  label: Text(
                    s.selectedTopic == null
                        ? s.question!.topicName
                        : '${s.selectedTopic!.subjectName} · ${s.selectedTopic!.name}',
                  ),
                ),
                const SectionHeader('Doğru cevap'),
                TextFormField(
                  initialValue: s.answer,
                  maxLength: 1,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: vm.answer,
                ),
                const SectionHeader('Hata nedeni'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: MistakeReason.values
                      .map(
                        (e) => ChoiceChip(
                          label: Text(reasonLabels[e]!),
                          selected: s.reason == e,
                          onSelected: (_) => vm.reason(e),
                        ),
                      )
                      .toList(),
                ),
                const SectionHeader('Zorluk'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: Difficulty.values
                      .map(
                        (e) => ChoiceChip(
                          label: Text(difficultyLabels[e]!),
                          selected: s.difficulty == e,
                          onSelected: (_) => vm.difficulty(e),
                        ),
                      )
                      .toList(),
                ),
                const SectionHeader('Kısa not'),
                TextFormField(
                  initialValue: s.note,
                  maxLength: 2000,
                  maxLines: 3,
                  onChanged: vm.note,
                ),
                const SectionHeader('Kaynak'),
                TextFormField(
                  initialValue: s.source,
                  maxLength: 500,
                  onChanged: vm.source,
                ),
                if (s.failure != null) ErrorView(error: s.failure!),
                HatoraPrimaryButton(
                  label: 'Değişiklikleri kaydet',
                  busy: s.busy,
                  busyLabel: 'Kaydediliyor…',
                  onPressed: vm.submit,
                ),
              ],
            ),
    );
  }
}

String _reviewLabelDetail(Question q) => q.status == QuestionStatus.mastered
    ? 'Öğrenildi'
    : q.nextReviewDate == null
    ? 'Planlanmamış'
    : 'Sonraki tekrar: ${friendlyDate(q.nextReviewDate!)}';

/// TR: Liste kartı, durum rozeti ve detay ekranı arasında paylaşılan tek
/// tarih biçimlendirici.
/// EN: The single date formatter shared by the list card, status chip, and
/// detail screen.
String friendlyDate(DateTime d) {
  final now = DateTime.now(),
      today = DateTime(now.year, now.month, now.day),
      day = DateTime(d.year, d.month, d.day);
  if (day == today) return 'Bugün';
  if (day == today.add(const Duration(days: 1))) return 'Yarın';
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  return '${d.day} ${months[d.month - 1]}';
}
