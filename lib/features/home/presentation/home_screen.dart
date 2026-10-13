import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/widget/components.dart';
import '../../../core/widget/startup_animation.dart';
import '../../dashboard/presentation/dashboard_view_model.dart';
import '../../dashboard/presentation/dashboard_widgets.dart';
import 'home_focus_card.dart';
import 'home_journey_header.dart';
import 'home_reference_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardViewModelProvider);
    final vm = ref.read(dashboardViewModelProvider.notifier);
    final name = ref.watch(authViewModelProvider).user?.displayName ?? '';

    ref.listen(dashboardViewModelProvider.select((s) => s.continueSession), (
      previous,
      next,
    ) {
      if (next != null) {
        vm.consumeContinueSession();
        context.push(Routes.reviewSession(next.sessionId), extra: next).then((
          _,
        ) {
          if (context.mounted) ref.invalidate(dashboardViewModelProvider);
        });
      }
    });
    ref.listen(dashboardViewModelProvider.select((s) => s.continueFailure), (
      previous,
      next,
    ) {
      if (next != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: PageBody(
          children: [
            if (state.phase == DashboardPhase.loading && state.summary == null)
              const HomeLoadingSkeleton()
            else if (state.summary == null)
              ErrorView(error: state.failure!, onRetry: vm.retry)
            else ...[
              if (state.failure != null)
                ErrorView(error: state.failure!, onRetry: vm.retry),
              HomeArrival(
                order: 0,
                child: HomeJourneyHeader(
                  name: name,
                  today: state.summary!.study?.today,
                  onProfile: () => context.push(Routes.profile),
                  onReminders: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (c) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Hatırlatmalar',
                              style: Theme.of(c).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.summary!.review.dueCount == 0
                                  ? 'Bugün bekleyen tekrarın yok.'
                                  : '${state.summary!.review.dueCount} sorunun tekrar zamanı geldi.',
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(c);
                                context.go(Routes.plan);
                              },
                              child: const Text('Planıma bak'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              HomeArrival(
                order: 1,
                child: HomeJourneyCountdown(
                  exam: state.summary!.activeExam,
                  onTap: () => context.push(Routes.profile),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bugünün Hata Antrenmanı',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(Routes.notebook),
                    child: const Text('Tümünü gör'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              HomeArrival(
                order: 2,
                child: HomeFocusCard(
                  review: state.summary!.review,
                  questionCount:
                      state.summary!.questions.activeCount +
                      state.summary!.questions.masteredCount,
                  hasQuestions:
                      state.summary!.questions.activeCount +
                          state.summary!.questions.masteredCount >
                      0,
                  busy: state.continuing,
                  label:
                      state.summary!.review.hasActiveReviewSession ||
                          state.summary!.review.dueCount > 0
                      ? reviewCtaLabel(state.summary!.review)
                      : state.summary!.questions.activeCount +
                                state.summary!.questions.masteredCount >
                            0
                      ? 'Defterime göz at'
                      : 'Yeni soru ekle',
                  onPressed: state.summary!.review.hasActiveReviewSession
                      ? vm.continueReview
                      : () async {
                          final route = state.summary!.review.dueCount > 0
                              ? Routes.review
                              : state.summary!.questions.activeCount +
                                        state.summary!.questions.masteredCount >
                                    0
                              ? Routes.notebook
                              : Routes.capture;
                          await context.push(route);
                          if (context.mounted) {
                            ref.invalidate(dashboardViewModelProvider);
                          }
                        },
                ),
              ),
              const SizedBox(height: 18),
              if (state.summary!.study != null)
                HomeArrival(
                  order: 3,
                  child: HomeWeekActivity(study: state.summary!.study!),
                ),
              const SectionHeader('Bir sonraki adım'),
              HomeQuickActions(
                study: state.summary!.study,
                onAdd: () => context.push(Routes.capture).then((_) {
                  if (context.mounted) {
                    ref.invalidate(dashboardViewModelProvider);
                  }
                }),
                onPlan: () => context.go(Routes.plan),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
