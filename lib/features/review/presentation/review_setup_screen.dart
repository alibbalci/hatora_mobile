import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widget/components.dart';
import 'review_states.dart';

class ReviewSetupScreen extends ConsumerWidget {
  const ReviewSetupScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewSetupViewModelProvider);
    final vm = ref.read(reviewSetupViewModelProvider.notifier);
    ref.listen(reviewSetupViewModelProvider.select((s) => s.started), (
      _,
      next,
    ) {
      if (next != null) {
        context.push(Routes.reviewSession(next.sessionId), extra: next);
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Bugünün tekrarı')),
      body: PageBody(
        children: switch (state.phase) {
          ReviewSetupPhase.loading => [
            const LoadingView(label: 'Tekrarların hazırlanıyor…'),
          ],
          ReviewSetupPhase.empty => [
            const EmptyView(
              icon: Icons.task_alt,
              title: 'Bugünlük tamam',
              message: 'Bugün tekrar etmen gereken soru bulunmuyor.',
            ),
          ],
          ReviewSetupPhase.error => [
            ErrorView(error: state.failure!, onRetry: vm.load),
          ],
          ReviewSetupPhase.ready || ReviewSetupPhase.starting => [
            Text(
              '${state.data!.totalDue} soru tekrar bekliyor',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.base),
            ChoiceChip(
              label: const Text('Karışık tekrar'),
              selected: state.selectedSubject == null,
              onSelected: state.phase == ReviewSetupPhase.starting
                  ? null
                  : (_) => vm.selectSubject(null),
            ),
            const SectionHeader('Derse göre'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: state.data!.subjects
                  .map(
                    (subject) => ChoiceChip(
                      label: Text('${subject.name} · ${subject.count}'),
                      selected: state.selectedSubject?.id == subject.id,
                      onSelected: state.phase == ReviewSetupPhase.starting
                          ? null
                          : (_) => vm.selectSubject(subject),
                    ),
                  )
                  .toList(),
            ),
            if (state.selectedSubject != null) ...[
              const SectionHeader('Konuya göre'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: state.topics
                    .map(
                      (topic) => ChoiceChip(
                        label: Text('${topic.name} · ${topic.count}'),
                        selected: state.selectedTopic?.id == topic.id,
                        onSelected: (_) => vm.selectTopic(topic),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            HatoraPrimaryButton(
              label: 'Tekrarı başlat',
              busy: state.phase == ReviewSetupPhase.starting,
              onPressed: vm.start,
            ),
          ],
        },
      ),
    );
  }
}
