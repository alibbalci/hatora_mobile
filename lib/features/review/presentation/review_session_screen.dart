import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../question/presentation/question_screens.dart';
import '../domain/review_models.dart';
import 'review_states.dart';
import 'review_session_view_model.dart';
import 'question_learned_moment.dart';
import '../../progress/presentation/daily_goal_complete_screen.dart';
import '../../progress/domain/progress_models.dart';

class ReviewSessionScreen extends ConsumerStatefulWidget {
  const ReviewSessionScreen({super.key, required this.session});
  final ReviewSessionContext session;
  @override
  ConsumerState<ReviewSessionScreen> createState() =>
      _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
  ReviewSessionContext get session => widget.session;
  bool advancing = false;
  @override
  Widget build(BuildContext context) {
    final provider = reviewSessionViewModelProvider(session);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    ref.listen(provider, (previous, next) {
      if (previous?.result != next.result && next.result != null) {
        ref.invalidate(progressViewModelProvider);
        ref.invalidate(dashboardViewModelProvider);
        ref.invalidate(myQuestionsViewModelProvider);
        ref.invalidate(statisticsViewModelProvider);
        ref.invalidate(questionDetailViewModelProvider);
      }
    });
    if (state.phase == ReviewSessionPhase.result && state.result != null) {
      ref.listen(_answeredProgressProvider(state.result!.itemId), (_, next) {
        final progress = next.asData?.value;
        if (progress != null && state.result?.mastered != true && !advancing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                ref.read(provider).result?.itemId == state.result!.itemId) {
              _celebrate(context, progress, vm);
            }
          });
        }
      });
      ref.watch(_answeredProgressProvider(state.result!.itemId));
    }
    if (state.phase == ReviewSessionPhase.result &&
        state.result?.mastered == true &&
        state.result?.skipped == false &&
        state.item != null) {
      return QuestionLearnedMoment(
        key: ValueKey(state.result!.itemId),
        item: state.item!,
        result: state.result!,
        image: state.image?.bytes,
        answerCount: session.answerOptionCount,
        onNext: () => _advance(context, state.result!, vm),
        onClose: () => context.go(Routes.review),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tekrar'),
        actions: [
          IconButton(
            tooltip: 'Karalama alanı',
            onPressed: () => context.push(Routes.drawing),
            icon: const Icon(Icons.draw_outlined),
          ),
        ],
      ),
      body: PageBody(children: _content(context, ref, state, vm)),
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    ReviewSessionState state,
    ReviewSessionViewModel vm,
  ) => switch (state.phase) {
    ReviewSessionPhase.loading => [
      const LoadingView(label: 'Sıradaki soru yükleniyor…'),
    ],
    ReviewSessionPhase.completed => [
      const EmptyView(
        icon: Icons.celebration_outlined,
        title: 'Tekrar tamamlandı',
        message: 'Oturumdaki tüm sorular backend tarafından işlendi.',
      ),
      const SizedBox(height: AppSpacing.base),
      HatoraPrimaryButton(
        label: 'Tekrarlara dön',
        onPressed: () => context.go(Routes.review),
      ),
    ],
    ReviewSessionPhase.inactive => [
      EmptyView(
        icon: Icons.event_busy_outlined,
        title: 'Oturum artık aktif değil',
        message: state.session?.status == ReviewSessionStatus.abandoned
            ? 'Bu oturum önceki bir güne ait olduğu için kapatıldı.'
            : 'Bu oturum artık cevap kabul etmiyor.',
      ),
      const SizedBox(height: AppSpacing.base),
      HatoraPrimaryButton(
        label: 'Tekrarlara dön',
        onPressed: () => context.go(Routes.review),
      ),
    ],
    ReviewSessionPhase.error => [
      ErrorView(
        error: state.failure!,
        onRetry: state.item == null ? vm.loadNext : null,
      ),
      if (state.item != null)
        HatoraPrimaryButton(label: 'Tekrar dene', onPressed: vm.submit),
    ],
    ReviewSessionPhase.ready || ReviewSessionPhase.submitting => [
      _ProgressHeader(item: state.item!),
      const SizedBox(height: AppSpacing.base),
      if (state.image != null) QuestionImageCard(bytes: state.image!.bytes),
      const SectionHeader('Cevabın'),
      AnswerOptions(
        count: session.answerOptionCount,
        selected: state.selectedAnswer,
        onSelected: vm.selectAnswer,
      ),
      const SizedBox(height: AppSpacing.sm),
      ChoiceChip(
        label: const Text('Çözemedim'),
        selected: state.unsolved,
        onSelected: (_) => vm.selectUnsolved(),
      ),
      if (state.failure != null) ErrorView(error: state.failure!),
      const SizedBox(height: AppSpacing.sm),
      HatoraPrimaryButton(
        label: 'Cevabı gönder',
        busy: state.phase == ReviewSessionPhase.submitting,
        onPressed: state.canSubmit ? vm.submit : null,
      ),
    ],
    ReviewSessionPhase.result => _result(context, ref, state, vm),
  };

  List<Widget> _result(
    BuildContext context,
    WidgetRef ref,
    ReviewSessionState state,
    ReviewSessionViewModel vm,
  ) {
    final result = state.result!;
    final (icon, color, title) = result.skipped
        ? (Icons.skip_next_rounded, AppColors.secondaryText, 'Soru atlandı')
        : switch (result.result!) {
            ReviewResult.correct => (
              Icons.check_circle_rounded,
              AppColors.success,
              'Doğru',
            ),
            ReviewResult.wrong => (
              Icons.cancel_rounded,
              AppColors.error,
              'Yanlış',
            ),
            ReviewResult.unsolved => (
              Icons.remove_circle_outline_rounded,
              AppColors.warning,
              'Çözülmedi',
            ),
          };
    return [
      Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
      const SizedBox(height: AppSpacing.base),
      if (state.image != null) QuestionImageCard(bytes: state.image!.bytes),
      if (!result.skipped) ...[
        const SectionHeader('Cevap anahtarı'),
        AnswerOptions(
          count: session.answerOptionCount,
          selected: result.selectedAnswer,
          onSelected: (_) {},
          correctAnswer: result.correctAnswer,
          revealed: true,
        ),
      ],
      const SizedBox(height: AppSpacing.base),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.skipped)
                Text(
                  'Soru arşivlendiği için yanlış sayılmadan atlandı.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (result.shortNote?.isNotEmpty == true)
                _infoLine(context, 'Not', result.shortNote!),
              if (result.mistakeReason != null)
                _infoLine(
                  context,
                  'Hata nedeni',
                  reasonLabels[result.mistakeReason]!,
                ),
              if (result.nextReviewDate != null)
                _infoLine(
                  context,
                  'Sonraki tekrar',
                  _date(result.nextReviewDate!),
                ),
              if (result.mastered)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Bu soru öğrenildi.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      if (result.solutionImages.isNotEmpty) ...[
        const SectionHeader('Çözüm görselleri'),
        for (final image in result.solutionImages)
          _ProtectedReviewImage(uri: image.imageUri),
      ],
      const SizedBox(height: AppSpacing.sm),
      HatoraPrimaryButton(
        label: result.sessionCompleted ? 'Tamamla' : 'Sıradaki soru',
        onPressed: () => _advance(context, result, vm),
      ),
    ];
  }

  Future<bool> _celebrate(
    BuildContext context,
    UserProgress progress,
    ReviewSessionViewModel vm,
  ) async {
    final userId = ref.read(authViewModelProvider).user?.id;
    if (userId == null ||
        !ref
            .read(dailyCelebrationGateProvider.notifier)
            .claim(userId, progress.today)) {
      return false;
    }
    advancing = true;
    final more = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog.fullscreen(
        child: DailyGoalCompleteScreen(
          progress: progress,
          onFinish: () => Navigator.pop(c, false),
          onMore: () => Navigator.pop(c, true),
        ),
      ),
    );
    advancing = false;
    if (!mounted || !context.mounted) return true;
    if (more == true) {
      await vm.loadNext();
    } else {
      context.go(Routes.home);
    }
    return true;
  }

  Future<void> _advance(
    BuildContext context,
    AnswerResult result,
    ReviewSessionViewModel vm,
  ) async {
    if (advancing) return;
    advancing = true;
    UserProgress? progress;
    try {
      progress = await ref.read(
        _answeredProgressProvider(result.itemId).future,
      );
    } catch (_) {
      /* The answer is saved; progress can be retried later. */
    }
    if (!mounted || !context.mounted) return;
    advancing = false;
    if (progress != null && await _celebrate(context, progress, vm)) return;
    if (mounted) await vm.loadNext();
  }

  Widget _infoLine(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.item});
  final NextReviewItem item;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              '${item.subjectName} · ${item.topicName}',
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Chip(label: Text(difficultyLabels[item.difficulty]!)),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: (item.position + 1) / item.totalItems,
          minHeight: 6,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${item.position + 1} / ${item.totalItems}',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    ],
  );
}

class _ProtectedReviewImage extends ConsumerWidget {
  const _ProtectedReviewImage({required this.uri});
  final Uri uri;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(reviewImageProvider(uri))
      .when(
        data: (image) => QuestionImageCard(bytes: image.bytes),
        loading: () => const LoadingView(label: 'Çözüm görseli yükleniyor…'),
        error: (error, _) => ErrorView(error: error),
      );
}

String _date(DateTime date) {
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

final _answeredProgressProvider = FutureProvider.autoDispose
    .family<UserProgress, String>(
      (ref, itemId) => ref.read(progressRepositoryProvider).getProgress(),
    );
