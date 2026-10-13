import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../../core/widget/reference_widgets.dart';
import '../../catalog/domain/catalog.dart';
import '../../export/presentation/export_screen.dart';
import '../domain/question.dart';
import '../../review/presentation/question_learned_moment.dart'
    show LearnedRouteBadge;
import 'my_questions_view_model.dart';
import 'question_detail_view_model.dart';
import 'question_screens.dart'
    show difficultyLabels, reasonLabels, QuestionReasonChoice;

class MyQuestionsScreen extends ConsumerStatefulWidget {
  const MyQuestionsScreen({super.key});
  @override
  ConsumerState<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends ConsumerState<MyQuestionsScreen> {
  final search = TextEditingController();
  Timer? timer;
  @override
  void dispose() {
    timer?.cancel();
    search.dispose();
    super.dispose();
  }

  void _filter({
    QuestionStatus? status,
    Difficulty? difficulty,
    bool changeStatus = false,
    bool changeDifficulty = false,
    String? query,
  }) {
    final old = ref.read(myQuestionsViewModelProvider).filters;
    ref
        .read(myQuestionsViewModelProvider.notifier)
        .setFilters(
          QuestionFilters(
            status: changeStatus ? status : old.status,
            difficulty: changeDifficulty ? difficulty : old.difficulty,
            search: query ?? old.search,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myQuestionsViewModelProvider),
        vm = ref.read(myQuestionsViewModelProvider.notifier);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 300) vm.loadMore();
            return false;
          },
          child: PageBody(
            children: [
              ReferenceHeader(
                title: 'Sorularım',
                caption: state.phase == MyQuestionsPhase.initialLoading
                    ? 'Soruların yükleniyor…'
                    : '${state.totalCount} soru',
                action: IconButton(
                  onPressed: () => openExportSheet(context),
                  tooltip: 'PDF Oluştur',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.line),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                ),
              ),
              TextField(
                controller: search,
                maxLength: 100,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
                decoration: const InputDecoration(
                  hintText: 'Ders veya konu ara',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) {
                  timer?.cancel();
                  timer = Timer(
                    const Duration(milliseconds: 300),
                    () => _filter(query: v),
                  );
                },
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in [
                      (QuestionStatus.active, 'Aktif'),
                      (QuestionStatus.mastered, 'Öğrenilen'),
                      (QuestionStatus.archived, 'Arşiv'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          backgroundColor: AppColors.surface,
                          shape: const StadiumBorder(
                            side: BorderSide(color: AppColors.line),
                          ),
                          label: Text(
                            '${entry.$2}${state.filters.status == entry.$1 ? ' ${state.totalCount}' : ''}',
                          ),
                          selected:
                              (state.filters.status ?? QuestionStatus.active) ==
                              entry.$1,
                          selectedColor: AppColors.primaryInk,
                          labelStyle: TextStyle(
                            color:
                                (state.filters.status ??
                                        QuestionStatus.active) ==
                                    entry.$1
                                ? AppColors.surface
                                : AppColors.primaryInk,
                          ),
                          onSelected: (_) =>
                              _filter(status: entry.$1, changeStatus: true),
                        ),
                      ),
                    PopupMenuButton<Difficulty?>(
                      tooltip: 'Zorluğa göre filtrele',
                      onSelected: (v) =>
                          _filter(difficulty: v, changeDifficulty: true),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: null,
                          child: Text('Tüm zorluklar'),
                        ),
                        for (final d in Difficulty.values)
                          PopupMenuItem(
                            value: d,
                            child: Text(difficultyLabels[d]!),
                          ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: .4),
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              state.filters.difficulty == null
                                  ? 'Zorluk'
                                  : difficultyLabels[state.filters.difficulty]!,
                              style: const TextStyle(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (state.phase == MyQuestionsPhase.initialLoading)
                const LoadingView(label: 'Soruların yükleniyor…')
              else if (state.failure != null && state.items.isEmpty)
                ErrorView(error: state.failure!, onRetry: vm.retry)
              else if (state.items.isEmpty)
                EmptyView(
                  title: state.filters.search?.isNotEmpty == true
                      ? 'Aramana uygun soru yok'
                      : 'Henüz soru eklemedin',
                  message: 'Kaydettiğin sorular, tekrar tarihini beklemeden burada görünür.',
                  icon: Icons.auto_stories_outlined,
                )
              else ...[
                Text(
                  state.filters.status == QuestionStatus.mastered
                      ? 'Öğrenilen sorular'
                      : state.filters.status == QuestionStatus.archived
                      ? 'Arşivlenen sorular'
                      : state.items.every(
                          (q) =>
                              q.nextReviewDate != null &&
                              !q.nextReviewDate!.isBefore(
                                DateUtils.dateOnly(DateTime.now()),
                              ) &&
                              q.nextReviewDate!.isBefore(
                                DateUtils.dateOnly(DateTime.now()).add(
                                  Duration(days: 8 - DateTime.now().weekday),
                                ),
                              ),
                        )
                      ? 'Bu hafta tekrar edilecek'
                      : 'Tekrar edilecek sorular',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 12),
                for (final q in state.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: QuestionSummaryCard(
                      question: q,
                      onTap: () =>
                          context.push(Routes.questionDetail(q.id)).then((_) {
                            if (mounted) vm.refresh();
                          }),
                    ),
                  ),
                if (state.phase == MyQuestionsPhase.loadingMore)
                  const LoadingView(),
                if (state.failure != null)
                  ErrorView(error: state.failure!, onRetry: vm.retry),
              ],
            ],
          ),
        ),
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
  Widget build(BuildContext context, WidgetRef ref) => ReferenceCard(
    padding: 14,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 90,
              height: 100,
              child: QuestionNetworkImage(uri: question.imageUri),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReferenceTag(
                  label: question.subjectName,
                  color: subjectColor(question.subjectName),
                ),
                const SizedBox(height: 8),
                Text(
                  question.topicName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ReferenceTag(
                      label: difficultyLabels[question.difficulty]!,
                      color: question.difficulty == Difficulty.hard
                          ? AppColors.error
                          : question.difficulty == Difficulty.medium
                          ? AppColors.warning
                          : AppColors.success,
                      icon: Icons.circle,
                    ),
                    if (question.status == QuestionStatus.mastered)
                      const ReferenceTag(
                        label: 'Öğrenildi',
                        color: AppColors.success,
                      )
                    else if (question.status == QuestionStatus.archived)
                      const ReferenceTag(
                        label: 'Arşivlendi',
                        color: AppColors.secondaryText,
                      )
                    else
                      Text(
                        question.nextReviewDate == null
                            ? 'Tekrar tarihi yok'
                            : referenceQuestionDate(question.nextReviewDate!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (question.status == QuestionStatus.mastered)
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: const CustomPaint(painter: LearnedRouteBadge()),
            )
          else
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.secondaryText,
              size: 18,
            ),
        ],
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
  const QuestionNetworkImage({
    super.key,
    required this.uri,
    this.fit = BoxFit.cover,
  });
  final BoxFit fit;
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
        fit: fit,
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

class QuestionDetailScreen extends ConsumerStatefulWidget {
  const QuestionDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<QuestionDetailScreen> createState() =>
      _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends ConsumerState<QuestionDetailScreen> {
  bool revealed = true;
  String get id => widget.id;
  @override
  Widget build(BuildContext context) {
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
        centerTitle: true,
        leading: IconButton(
          style: _circleButton(),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.question != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Düzenle',
              style: _circleButton(),
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
    final color = q.difficulty == Difficulty.easy
        ? AppColors.success
        : q.difficulty == Difficulty.hard
        ? AppColors.error
        : AppColors.warning;
    final count = ref
        .watch(_detailCatalogProvider(q.examId))
        .asData
        ?.value
        .exam
        .answerOptionCount;
    return PageBody(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryInk,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: ColoredBox(
                    color: const Color(0xFFFAFAF7),
                    child: QuestionNetworkImage(
                      uri: q.imageUri,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryInk.withValues(
                      alpha: .75,
                    ),
                    foregroundColor: AppColors.surface,
                  ),
                  onPressed: () => _fullPhoto(context, q.imageUri),
                  icon: const Icon(Icons.fullscreen, size: 17),
                  label: const Text('Büyüt'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            ReferenceTag(
              label: q.subjectName,
              color: subjectColor(q.subjectName),
            ),
            const Spacer(),
            ReferenceTag(
              label: q.status == QuestionStatus.active
                  ? 'Aktif'
                  : q.status == QuestionStatus.mastered
                  ? 'Öğrenildi'
                  : 'Arşivlendi',
              color: q.status == QuestionStatus.archived
                  ? AppColors.secondaryText
                  : AppColors.success,
              icon: Icons.circle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(q.topicName, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                'Doğru cevap',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => revealed = !revealed),
              icon: Icon(
                revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 17,
              ),
              label: Text(revealed ? 'Gizle' : 'Göster'),
            ),
          ],
        ),
        if (count != null)
          _QuestionAnswerRow(
            count: count,
            answer: revealed ? q.correctAnswer : null,
          )
        else if (ref.watch(_detailCatalogProvider(q.examId)).hasError)
          Text(revealed ? 'Doğru cevap: ${q.correctAnswer}' : 'Cevap gizli'),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ReferenceCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zorluk',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: color),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            difficultyLabels[q.difficulty]!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ReferenceCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hata nedeni',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reasonLabels[q.mistakeReason]!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const _QuestionHeading('Tekrar'),
        ReferenceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      q.nextReviewDate == null
                          ? '—'
                          : '${_shortMonth(q.nextReviewDate!.month)}\n${q.nextReviewDate!.day}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sonraki tekrar',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          q.status == QuestionStatus.mastered
                              ? 'Öğrenildi'
                              : _nextReviewText(q.nextReviewDate),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Expanded(
                      child: Container(
                        height: 7,
                        margin: EdgeInsets.only(right: i == 4 ? 0 : 5),
                        decoration: BoxDecoration(
                          color: i < q.reviewStage
                              ? AppColors.accent
                              : AppColors.line,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                q.firstReviewedAt == null
                    ? 'Henüz tekrar edilmedi'
                    : 'Tekrar aşaması: ${q.reviewStage}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const _QuestionHeading('Notun'),
        if (q.shortNote.isNotEmpty || q.source.isNotEmpty)
          ReferenceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (q.shortNote.isNotEmpty) Text(q.shortNote),
                if (q.source.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(q.source, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          )
        else
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              side: const BorderSide(color: AppColors.line),
            ),
            onPressed: () =>
                context.push(Routes.questionEdit(id)).then((_) => vm.load()),
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Not veya kaynak ekle'),
          ),
        if (q.solutionImages.isNotEmpty) ...[
          const _QuestionHeading('Çözüm görselleri'),
          for (final i in q.solutionImages)
            InkWell(
              onTap: () => _fullPhoto(context, i.imageUri),
              child: SizedBox(
                height: 220,
                child: QuestionNetworkImage(
                  uri: i.imageUri,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
        if (state.failure != null) ErrorView(error: state.failure!),
        const SizedBox(height: 28),
        const Divider(),
        if (q.status != QuestionStatus.archived)
          TextButton.icon(
            onPressed: state.phase == QuestionDetailPhase.archiving
                ? null
                : () => _archive(context, vm),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondaryText,
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

class QuestionEditScreen extends ConsumerStatefulWidget {
  const QuestionEditScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<QuestionEditScreen> createState() => _QuestionEditScreenState();
}

class _QuestionEditScreenState extends ConsumerState<QuestionEditScreen> {
  int revision = 0;
  @override
  Widget build(BuildContext context) {
    final p = questionEditViewModelProvider(widget.id),
        s = ref.watch(p),
        vm = ref.read(p.notifier),
        q = s.question;
    ref.listen(p, (a, b) {
      if (a?.saved == null && b.saved != null) context.pop(b.saved);
    });
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Soruyu düzenle'),
        leadingWidth: 84,
        leading: TextButton(
          onPressed: s.busy ? null : () => context.pop(),
          child: const Text('Vazgeç'),
        ),
      ),
      bottomNavigationBar: q == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${s.changeCount} değişiklik',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: s.busy || s.changeCount == 0
                              ? null
                              : () {
                                  vm.revert();
                                  setState(() => revision++);
                                },
                          icon: const Icon(Icons.undo_rounded, size: 17),
                          label: const Text('Geri al'),
                        ),
                      ],
                    ),
                    HatoraPrimaryButton(
                      solidColor: AppColors.accent,
                      label: 'Değişiklikleri kaydet',
                      busy: s.busy,
                      busyLabel: 'Kaydediliyor…',
                      onPressed: s.changeCount == 0 ? null : vm.submit,
                    ),
                  ],
                ),
              ),
            ),
      body: s.loading
          ? const LoadingView()
          : q == null
          ? PageBody(
              children: [ErrorView(error: s.failure!, onRetry: vm.load)],
            )
          : PageBody(
              children: [
                ReferenceCard(
                  padding: 12,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: QuestionNetworkImage(
                            uri: q.imageUri,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ders ve konu',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${s.selectedTopic?.subjectName ?? q.subjectName} · ${s.selectedTopic?.name ?? q.topicName}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: s.busy || s.topics.isEmpty
                            ? null
                            : () async {
                                final topic = await context.push<Topic>(
                                  Routes.topics,
                                  extra: s.topics,
                                );
                                if (mounted && topic != null) vm.topic(topic);
                              },
                        child: const Text('Değiştir'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Doğru cevap',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (s.answer != q.correctAnswer)
                      ReferenceTag(
                        label: '${q.correctAnswer} → ${s.answer}',
                        color: AppColors.warning,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _QuestionAnswerRow(
                  count: s.answerOptionCount,
                  answer: s.answer,
                  original: q.correctAnswer,
                  onChanged: s.busy ? null : vm.answer,
                ),
                const _QuestionHeading('Hata nedeni'),
                LayoutBuilder(
                  builder: (context, c) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: reasonLabels.entries
                        .map(
                          (e) => SizedBox(
                            width:
                                e.key == MistakeReason.other ||
                                    MediaQuery.textScalerOf(context).scale(14) >
                                        18
                                ? c.maxWidth
                                : (c.maxWidth - 10) / 2,
                            child: QuestionReasonChoice(
                              label: e.value,
                              selected: s.reason == e.key,
                              onTap: s.busy ? null : () => vm.reason(e.key),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const _QuestionHeading('Zorluk'),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      for (final e in [
                        (Difficulty.easy, 'Kolay', AppColors.success),
                        (Difficulty.medium, 'Orta', AppColors.warning),
                        (Difficulty.hard, 'Zor', AppColors.error),
                      ])
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: s.difficulty == e.$1
                                  ? AppColors.surface
                                  : Colors.transparent,
                              foregroundColor: AppColors.primaryInk,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: s.busy
                                ? null
                                : () => vm.difficulty(e.$1),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                children: [
                                  Icon(Icons.circle, size: 7, color: e.$3),
                                  const SizedBox(width: 7),
                                  Text(e.$2),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const _QuestionHeading('Ek bilgiler', optional: true),
                TextFormField(
                  key: ValueKey('note-$revision'),
                  enabled: !s.busy,
                  initialValue: s.note,
                  maxLength: 2000,
                  maxLines: 3,
                  onChanged: vm.note,
                  decoration: const InputDecoration(
                    hintText: 'Bir dahaki sefere neyi hatırlamak istersin?',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('source-$revision'),
                  enabled: !s.busy,
                  initialValue: s.source,
                  maxLength: 500,
                  onChanged: vm.source,
                  decoration: const InputDecoration(
                    hintText: 'Kitap veya deneme adı',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                    counterText: '',
                  ),
                ),
                if (s.failure != null) ErrorView(error: s.failure!),
              ],
            ),
    );
  }
}

final _detailCatalogProvider = FutureProvider.autoDispose
    .family<QuestionCatalog, String>(
      (ref, id) => ref.read(catalogRepositoryProvider).questionCatalog(id),
    );
ButtonStyle _circleButton() => IconButton.styleFrom(
  backgroundColor: AppColors.surface,
  shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
);
Future<void> _fullPhoto(BuildContext context, Uri? uri) => showDialog<void>(
  context: context,
  builder: (c) => Dialog.fullscreen(
    child: Scaffold(
      backgroundColor: AppColors.primaryInk,
      appBar: AppBar(
        title: const Text('Soru fotoğrafı'),
        leading: IconButton(
          onPressed: () => Navigator.pop(c),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: .5,
          maxScale: 5,
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(c).height * .7,
            child: QuestionNetworkImage(uri: uri, fit: BoxFit.contain),
          ),
        ),
      ),
    ),
  ),
);

class _QuestionHeading extends StatelessWidget {
  const _QuestionHeading(this.title, {this.optional = false});
  final String title;
  final bool optional;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (optional)
          Text('İsteğe bağlı', style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _QuestionAnswerRow extends StatelessWidget {
  const _QuestionAnswerRow({
    required this.count,
    this.answer,
    this.original,
    this.onChanged,
  });
  final int count;
  final String? answer, original;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              padding: EdgeInsets.zero,
              backgroundColor: answer == String.fromCharCode(65 + i)
                  ? AppColors.success
                  : AppColors.surface,
              foregroundColor: answer == String.fromCharCode(65 + i)
                  ? AppColors.surface
                  : AppColors.secondaryText,
              disabledForegroundColor: answer == String.fromCharCode(65 + i)
                  ? AppColors.surface
                  : AppColors.secondaryText,
              disabledBackgroundColor: answer == String.fromCharCode(65 + i)
                  ? AppColors.success
                  : AppColors.surface,
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onChanged == null
                ? null
                : () => onChanged!(String.fromCharCode(65 + i)),
            child: Text(
              String.fromCharCode(65 + i),
              style: TextStyle(
                decoration:
                    original == String.fromCharCode(65 + i) &&
                        original != answer
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

String _shortMonth(int month) => [
  'OCA',
  'ŞUB',
  'MAR',
  'NİS',
  'MAY',
  'HAZ',
  'TEM',
  'AGU',
  'EYL',
  'EKİ',
  'KAS',
  'ARA',
][month - 1];
String _nextReviewText(DateTime? date) {
  if (date == null) return 'Planlanmamış';
  final d = DateUtils.dateOnly(date)
      .difference(DateUtils.dateOnly(DateTime.now()))
      .inDays;
  return '${['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'][date.weekday - 1]} · ${d == 0
      ? 'bugün'
      : d == 1
      ? 'yarın'
      : d > 1
      ? '$d gün sonra'
      : '${-d} gün önce'}';
}

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

String referenceQuestionDate(DateTime date) {
  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final days = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(today).inDays;
  if (days == 0) return 'Bugün';
  if (days == 1) return 'Yarın';
  const months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  return '${date.day} ${months[date.month - 1]} · ${days < 0 ? -days : days} gün${days < 0 ? ' gecikti' : ''}';
}
