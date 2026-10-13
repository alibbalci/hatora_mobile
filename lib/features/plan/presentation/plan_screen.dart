import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../../core/widget/reference_widgets.dart';
import '../../dashboard/domain/dashboard_models.dart';
import '../../dashboard/presentation/dashboard_widgets.dart'
    show reviewCtaLabel;

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});
  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  DateTime? selected;
  bool all = false;
  bool same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider),
        vm = ref.read(dashboardViewModelProvider.notifier),
        summary = state.summary;
    ref.listen(dashboardViewModelProvider.select((s) => s.continueSession), (
      _,
      next,
    ) {
      if (next != null) {
        vm.consumeContinueSession();
        context.push(Routes.reviewSession(next.sessionId), extra: next).then((
          _,
        ) {
          if (mounted) ref.invalidate(dashboardViewModelProvider);
        });
      }
    });
    ref.listen(dashboardViewModelProvider.select((s) => s.continueFailure), (
      _,
      failure,
    ) {
      if (failure != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    });
    final today = summary?.study?.today ?? DateTime.now();
    final date = selected ?? today;
    final isToday = same(today, date);
    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    final upcoming = summary?.study?.upcomingDays ?? const <UpcomingStudyDay>[];
    final dayRows = upcoming.where((d) => same(d.date, date)).toList();
    final due = isToday
        ? (summary?.review.dueCount ?? 0)
        : dayRows.fold<int>(0, (n, d) => n + d.questionCount);
    final free =
        due == 0 &&
        !(isToday && (summary?.review.hasActiveReviewSession ?? false));
    final effective = summary?.review.effectiveReviewGoal ?? 0;
    final ratio = free
        ? 1.0
        : !isToday || effective <= 0
        ? 0.0
        : ((summary?.review.reviewsCompletedToday ?? 0) / effective).clamp(
            0.0,
            1.0,
          );
    const days = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
    final list = (all ? upcoming : upcoming.take(3)).toList();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: PageBody(
          children: [
            ReferenceHeader(
              title: 'Çalışma planı',
              caption: referenceDate(today).split(' ').skip(1).join(' '),
              action: IconButton(
                tooltip: 'Bugüne dön',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.line),
                ),
                onPressed: () => setState(() => selected = null),
                icon: const Icon(Icons.today_outlined),
              ),
            ),
            Row(
              children: List.generate(7, (i) {
                final d = monday.add(Duration(days: i)), active = same(d, date);
                final scheduled =
                    upcoming.any((u) => same(u.date, d)) ||
                    (same(d, today) && (summary?.review.dueCount ?? 0) > 0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => setState(() => selected = d),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primaryInk
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Text(
                              days[i],
                              style: TextStyle(
                                color: active
                                    ? AppColors.surface.withValues(alpha: .7)
                                    : AppColors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${d.day}',
                              style: TextStyle(
                                color: active
                                    ? AppColors.surface
                                    : AppColors.primaryInk,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: active
                                    ? AppColors.surface
                                    : scheduled
                                    ? AppColors.accent
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            if (summary == null)
              if (state.failure != null)
                ErrorView(error: state.failure!, onRetry: vm.retry)
              else
                const LoadingView(label: 'Planın yükleniyor…')
            else ...[
              if (state.failure != null)
                ErrorView(error: state.failure!, onRetry: vm.retry),
              ReferenceCard(
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, c) {
                        final ring = SizedBox(
                          width: 92,
                          height: 92,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: ratio,
                                  strokeWidth: 9,
                                  color: free
                                      ? AppColors.success
                                      : AppColors.accent,
                                  backgroundColor: AppColors.surfaceMuted,
                                ),
                              ),
                              Icon(
                                free
                                    ? Icons.check_rounded
                                    : Icons.flag_outlined,
                                color: free
                                    ? AppColors.success
                                    : AppColors.accent,
                                size: 27,
                              ),
                            ],
                          ),
                        );
                        final text = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isToday ? 'Bugünkü hedefin' : referenceDate(date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              free
                                  ? (isToday
                                        ? 'Bugün serbestsin'
                                        : 'Planlı tekrar yok')
                                  : '$due soru tekrar bekliyor',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              free
                                  ? 'Tekrar zamanı gelen soru yok. Dinlenebilir ya da yeni soru ekleyebilirsin.'
                                  : isToday
                                  ? '${summary.review.reviewsCompletedToday} / ${summary.review.effectiveReviewGoal} tekrar tamamlandı.'
                                  : 'Bu gün için kayıtlı soruların tekrar zamanı gelecek.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.secondaryText),
                            ),
                          ],
                        );
                        if (c.maxWidth < 260 ||
                            MediaQuery.textScalerOf(context).scale(14) > 18) {
                          return Column(
                            children: [ring, const SizedBox(height: 16), text],
                          );
                        }
                        return Row(
                          children: [
                            ring,
                            const SizedBox(width: 22),
                            Expanded(child: text),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 64),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: state.continuing
                                ? null
                                : !free && isToday
                                ? summary.review.hasActiveReviewSession
                                      ? vm.continueReview
                                      : () => context.push(Routes.review).then((
                                          _,
                                        ) {
                                          if (mounted) {
                                            ref.invalidate(
                                              dashboardViewModelProvider,
                                            );
                                          }
                                        })
                                : () => context.push(Routes.capture),
                            icon: Icon(
                              free
                                  ? Icons.add_a_photo_outlined
                                  : Icons.play_arrow_rounded,
                              size: 17,
                            ),
                            label: Text(
                              free
                                  ? 'Soru ekle'
                                  : reviewCtaLabel(summary.review),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.surfaceMuted,
                              foregroundColor: AppColors.accent,
                              minimumSize: const Size(0, 64),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () => _goal(context),
                            icon: const Icon(Icons.flag_outlined, size: 17),
                            label: const Text(
                              'Hedefi düzenle',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Yaklaşan tekrarlar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => all = !all),
                    child: Text(all ? 'Daha az' : 'Tümü'),
                  ),
                ],
              ),
              ReferenceCard(
                child: list.isEmpty
                    ? Text(
                        summary.study == null ? 'Takvim verisi yükleniyor…' : 'Henüz yaklaşan tekrar yok. Eklediğin soruların tekrar tarihleri burada görünür.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < list.length; i++) ...[
                            if (i > 0) const Divider(height: 28),
                            InkWell(
                              onTap: () =>
                                  setState(() => selected = list[i].date),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 48,
                                    child: Column(
                                      children: [
                                        Text(
                                          [
                                            'Pzt',
                                            'Sal',
                                            'Çar',
                                            'Per',
                                            'Cum',
                                            'Cmt',
                                            'Paz',
                                          ][list[i].date.weekday - 1],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        Text(
                                          '${list[i].date.day}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${list[i].questionCount} soru',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 7),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: list[i].subjects
                                              .map(
                                                (s) => ReferenceTag(
                                                  label: s,
                                                  color: subjectColor(s),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: AppColors.secondaryText,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _goal(BuildContext context) async {
    final status = await ref.read(onboardingRepositoryProvider).status();
    if (!context.mounted) return;
    final value = await showDialog<String>(
      context: context,
      builder: (_) => ReferenceInputDialog(
        title: 'Günlük tekrar hedefi',
        initialValue: '${status.dailyReviewGoal}',
        numeric: true,
      ),
    );
    final goal = int.tryParse(value ?? '');
    if (goal != null && mounted) {
      await ref.read(profileViewModelProvider.notifier).updateGoal(goal);
      if (mounted) ref.invalidate(dashboardViewModelProvider);
    }
  }
}
