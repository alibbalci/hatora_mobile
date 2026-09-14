import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/design/app_secondary_button.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widget/components.dart';
import '../../dashboard/presentation/dashboard_view_model.dart';
import '../../dashboard/presentation/dashboard_widgets.dart';

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
        context
            .push(Routes.reviewSession(next.sessionId), extra: next)
            .then((_) => ref.invalidate(dashboardViewModelProvider));
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
      appBar: AppBar(
        title: Text(
          'Merhaba, $name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: PageBody(
          children: [
            if (state.phase == DashboardPhase.loading && state.summary == null)
              const LoadingView(label: 'Panel yükleniyor…')
            else if (state.summary == null)
              ErrorView(error: state.failure!, onRetry: vm.retry)
            else ...[
              if (state.failure != null)
                ErrorView(error: state.failure!, onRetry: vm.retry),
              DashboardActiveExamCard(exam: state.summary!.activeExam),
              const SizedBox(height: AppSpacing.base),
              DashboardReviewProgressCard(review: state.summary!.review),
              HatoraPrimaryButton(
                label: reviewCtaLabel(state.summary!.review),
                busy: state.continuing,
                onPressed: state.summary!.review.hasActiveReviewSession
                    ? vm.continueReview
                    : state.summary!.review.dueCount > 0
                    ? () => context
                          .push(Routes.review)
                          .then(
                            (_) => ref.invalidate(dashboardViewModelProvider),
                          )
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              DashboardStatGrid(
                progress: state.summary!.progress,
                questions: state.summary!.questions,
              ),
              const SectionHeader('Hata defterin'),
              AppSecondaryButton(
                label: 'Yeni soru ekle',
                icon: Icons.add_a_photo_outlined,
                onPressed: () => context
                    .push(Routes.capture)
                    .then((_) => ref.invalidate(dashboardViewModelProvider)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
