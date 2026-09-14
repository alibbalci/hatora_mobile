import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../auth/presentation/auth_view_model.dart';

class ExamSelectionScreen extends ConsumerWidget {
  const ExamSelectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final vm = ref.read(onboardingViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Hatora')),
      body: PageBody(
        children: [
          const _Progress(step: 0),
          Text(
            'Hangi sınava\nhazırlanıyorsun?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ders ve konu listeni buna göre hazırlayalım.',
            style: TextStyle(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 28),
          state.choices.when(
            data: (choices) => Column(
              children: [
                if (choices.isEmpty)
                  const EmptyView(
                    title: 'Sınav bulunamadı',
                    message: 'Sınav listesi henüz hazır değil.',
                  ),
                ...choices.map(
                  (exam) => SelectableOptionCard(
                    title: exam.label,
                    subtitle: exam.exam.code,
                    selected: state.selectedExam?.editionId == exam.editionId,
                    onTap: () => vm.selectExam(exam),
                  ),
                ),
              ],
            ),
            loading: () => const LoadingView(label: 'Sınavlar yükleniyor…'),
            error: (error, _) => ErrorView(error: error, onRetry: vm.load),
          ),
          HatoraPrimaryButton(
            label: 'Devam et',
            onPressed: state.selectedExam == null
                ? null
                : () {
                    vm.setStep(1);
                    context.push(Routes.goal);
                  },
          ),
          if (ref.watch(authViewModelProvider).status == AuthStatus.guest)
            TextButton(
              onPressed: () => context.push(Routes.auth),
              child: const Text('Zaten hesabım var · Giriş yap'),
            ),
        ],
      ),
    );
  }
}

class DailyGoalScreen extends ConsumerWidget {
  const DailyGoalScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final vm = ref.read(onboardingViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Günlük hedef')),
      body: PageBody(
        children: [
          const _Progress(step: 1),
          Text(
            'Küçük adımlar,\nkalıcı öğrenme.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text('Günde kaç soru tekrar etmek istersin?'),
          const SizedBox(height: 24),
          for (final goal in [5, 10, 15, 20])
            SelectableOptionCard(
              title: '$goal soru',
              subtitle: goal == 10 ? 'Dengeli tempo' : null,
              selected: state.dailyReviewGoal == goal,
              onTap: () => vm.setDailyGoal(goal),
            ),
          HatoraPrimaryButton(
            label: 'Devam et',
            onPressed: () {
              vm.setStep(2);
              context.push(Routes.value);
            },
          ),
        ],
      ),
    );
  }
}

class ValuePropositionScreen extends ConsumerWidget {
  const ValuePropositionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final auth = ref.watch(authViewModelProvider);
    final authenticated = auth.status == AuthStatus.authenticated;
    if (authenticated &&
        state.selectedExam != null &&
        !state.completed &&
        !state.busy &&
        state.failure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final current = ref.read(onboardingViewModelProvider);
        if (current.selectedExam != null &&
            !current.completed &&
            !current.busy &&
            current.failure == null) {
          ref
              .read(onboardingViewModelProvider.notifier)
              .complete(authenticated: true);
        }
      });
    }
    ref.listen(onboardingViewModelProvider.select((s) => s.completed), (
      previous,
      next,
    ) {
      if (next && previous != true) {
        ref.read(authViewModelProvider.notifier).restore();
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Senin öğrenme yolculuğun')),
      body: PageBody(
        children: [
          const _Progress(step: 2),
          Text(
            'Ders ve konuyu\nbirlikte bulalım.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const Text(
            'Soruyu fotoğrafla. AI ders ve konu önersin. Son karar her zaman senin.',
          ),
          const SizedBox(height: 24),
          const EmptyView(
            icon: Icons.auto_awesome_outlined,
            title: 'Fotoğraf → Öneri → Senin onayın',
            message: 'Öneriyi değiştirebilir veya konuyu kendin seçebilirsin.',
          ),
          const SectionHeader('Planın hazır'),
          if (authenticated && auth.user?.onboardingCompleted != true)
            Card(
              color: AppColors.successSoft,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Giriş başarılı. Son adım olarak sınav ve günlük hedef seçimini kaydet.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Text(state.selectedExam?.label ?? 'Sınav seçimi bekleniyor'),
          Text('Günlük hedefin: ${state.dailyReviewGoal} soru'),
          const SizedBox(height: 20),
          if (state.failure != null) ErrorView(error: state.failure!),
          if (auth.failure != null) ErrorView(error: auth.failure!),
          HatoraPrimaryButton(
            label: authenticated
                ? state.failure == null
                      ? 'Seçimler kaydediliyor'
                      : 'Kaydetmeyi tekrar dene'
                : 'Hesabımla devam et',
            busy: state.busy || auth.busy,
            onPressed: state.selectedExam == null
                ? null
                : () {
                    if (authenticated) {
                      if (state.completed) {
                        ref.read(authViewModelProvider.notifier).restore();
                      } else if (!state.busy) {
                        ref
                            .read(onboardingViewModelProvider.notifier)
                            .complete(authenticated: true);
                      }
                    } else {
                      context.push(Routes.auth);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i <= step ? AppColors.accent : AppColors.line,
            ),
          ),
        ),
      ),
    ),
  );
}
