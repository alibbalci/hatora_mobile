import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../../core/widget/reference_widgets.dart';
import '../../../core/time/calendar_date.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../catalog/domain/catalog.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.primaryInk,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (c.maxHeight - 56).clamp(0, double.infinity),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/hatora-logo.png',
                          width: 44,
                          height: 44,
                          semanticLabel: 'Hatora logosu',
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Hatora',
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Yanlışların,\nen iyi öğretmenin.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.surface,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Çözemediğin soruları biriktir, doğru zamanda tekrar et, sınavda aynı hatayı yapma.',
                    style: TextStyle(
                      color: Color(0xFFB7B2D7),
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 30),
                  for (final e in [
                    (
                      Icons.add_a_photo_outlined,
                      'Fotoğrafla',
                      'Yanlış yaptığın soruyu çek',
                      AppColors.surface,
                    ),
                    (
                      Icons.auto_awesome_outlined,
                      'AI konusunu bulsun',
                      'Son karar her zaman senin',
                      Color(0xFF9BE2C4),
                    ),
                    (
                      Icons.event_repeat,
                      'Zamanında tekrar et',
                      'Unutmadan önce önüne gelir',
                      Color(0xFFFFB585),
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF302C61),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(e.$1, color: e.$4, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.$2,
                                  style: const TextStyle(
                                    color: AppColors.surface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  e.$3,
                                  style: const TextStyle(
                                    color: Color(0xFFB7B2D7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.accent,
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => context.push(Routes.exams),
                    child: const Text('Hadi başlayalım'),
                  ),
                  TextButton(
                    onPressed: () => context.push(Routes.auth),
                    child: const Text(
                      'Zaten hesabım var · Giriş yap',
                      style: TextStyle(color: Color(0xFFB7B2D7)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ExamSelectionScreen extends ConsumerWidget {
  const ExamSelectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider),
        vm = ref.read(onboardingViewModelProvider.notifier);
    return _OnboardingFrame(
      step: 0,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.welcome);
        }
      },
      footer: HatoraPrimaryButton(
        solidColor: AppColors.accent,
        label: 'Devam et',
        onPressed: state.selectedExam == null
            ? null
            : () {
                vm.setStep(1);
                context.push(Routes.goal);
              },
      ),
      children: [
        const _Intro(
          step: 1,
          title: 'Hangi sınava\nhazırlanıyorsun?',
          subtitle: 'Ders ve konu listeni buna göre hazırlayalım.',
        ),
        const SizedBox(height: 28),
        state.choices.when(
          loading: () => const LoadingView(label: 'Sınavlar yükleniyor…'),
          error: (e, _) => ErrorView(error: e, onRetry: vm.load),
          data: (choices) => Column(
            children: [
              if (choices.isEmpty)
                const EmptyView(
                  title: 'Sınav bulunamadı',
                  message: 'Sınav listesi henüz hazır değil.',
                ),
              for (final exam in choices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExamOption(
                    exam: exam,
                    selected: state.selectedExam?.editionId == exam.editionId,
                    onTap: () => vm.selectExam(exam),
                  ),
                ),
            ],
          ),
        ),
        const _InfoBox(
          text: "Sınavını sonra Profil'den değiştirebilirsin.",
          color: AppColors.accent,
          background: AppColors.accentSoft,
        ),
      ],
    );
  }
}

class DailyGoalScreen extends ConsumerWidget {
  const DailyGoalScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(onboardingViewModelProvider),
        vm = ref.read(onboardingViewModelProvider.notifier),
        days = _days(s.selectedExam?.examDate);
    return _OnboardingFrame(
      step: 1,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.exams);
        }
      },
      footer: HatoraPrimaryButton(
        solidColor: AppColors.accent,
        label: 'Devam et',
        onPressed: () {
          vm.setStep(2);
          context.push(Routes.value);
        },
      ),
      children: [
        const _Intro(
          step: 2,
          title: 'Küçük adımlar,\nkalıcı öğrenme.',
          subtitle: 'Günde kaç soru tekrar etmek istersin?',
        ),
        const SizedBox(height: 28),
        ReferenceCard(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Hedefi azalt',
                    onPressed: s.dailyReviewGoal <= 1
                        ? null
                        : () => vm.setDailyGoal(s.dailyReviewGoal - 1),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${s.dailyReviewGoal}',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                fontSize: 58,
                                color: AppColors.primaryInk,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          'soru / gün',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Hedefi artır',
                    onPressed: s.dailyReviewGoal >= 200
                        ? null
                        : () => vm.setDailyGoal(s.dailyReviewGoal + 1),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ReferenceTag(
                label: s.dailyReviewGoal <= 5
                    ? 'Hafif tempo'
                    : s.dailyReviewGoal <= 10
                    ? 'Dengeli tempo'
                    : s.dailyReviewGoal <= 20
                    ? 'Düzenli tempo'
                    : 'Yoğun tempo',
                color: AppColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final goal in [5, 10, 15, 20]) ...[
              if (goal != 5) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: s.dailyReviewGoal == goal
                        ? AppColors.primaryInk
                        : AppColors.surface,
                    foregroundColor: s.dailyReviewGoal == goal
                        ? AppColors.surface
                        : AppColors.primaryInk,
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => vm.setDailyGoal(goal),
                  child: Text('$goal'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _InfoBox(
          text: days != null && days >= 0
              ? 'Sınava kadar bu tempoyla ${days * s.dailyReviewGoal} tekrar planlamış olursun.'
              : 'Her gün ${s.dailyReviewGoal} soruyla düzenli tekrar alışkanlığı kazanabilirsin.',
          color: AppColors.warning,
          background: const Color(0xFFFFF5EA),
        ),
      ],
    );
  }
}

class ValuePropositionScreen extends ConsumerWidget {
  const ValuePropositionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider),
        auth = ref.watch(authViewModelProvider),
        authenticated = auth.status == AuthStatus.authenticated;
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
    final exam = state.selectedExam;
    return _OnboardingFrame(
      step: 2,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.goal);
        }
      },
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HatoraPrimaryButton(
            solidColor: AppColors.accent,
            label: authenticated
                ? (state.failure == null
                      ? 'Seçimler kaydediliyor'
                      : 'Kaydetmeyi tekrar dene')
                : 'E-postayla hesap oluştur',
            busy: state.busy || auth.busy,
            onPressed: exam == null
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
                      context.push('${Routes.auth}?register=1');
                    }
                  },
          ),
          if (!authenticated)
            TextButton(
              onPressed: () => context.push(Routes.auth),
              child: const Text('Zaten hesabım var · Giriş yap'),
            ),
        ],
      ),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: AppColors.surface,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Planın hazır',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontSize: 28, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          authenticated
              ? 'Seçimlerini kaydediyoruz.'
              : 'Kaydetmek için ücretsiz hesabını oluştur.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: 28),
        ReferenceCard(
          padding: 16,
          child: Column(
            children: [
              _SummaryRow(
                icon: Icons.school_outlined,
                label: 'Sınav',
                value: exam == null
                    ? 'Sınav seçimi bekleniyor'
                    : _examTitle(exam),
                onChange: () => context.go(Routes.exams),
              ),
              const Divider(height: 28),
              _SummaryRow(
                icon: Icons.event_outlined,
                label: 'Sınav tarihi',
                value: exam == null ? 'Tarih bekleniyor' : _examDate(exam),
                color: const Color(0xFF2273B9),
              ),
              const Divider(height: 28),
              _SummaryRow(
                icon: Icons.flag_outlined,
                label: 'Günlük hedef',
                value: '${state.dailyReviewGoal} soru',
                color: AppColors.success,
                onChange: () => context.go(Routes.goal),
              ),
            ],
          ),
        ),
        if (state.failure != null) ErrorView(error: state.failure!),
        if (auth.failure != null) ErrorView(error: auth.failure!),
      ],
    );
  }
}

class _OnboardingFrame extends StatelessWidget {
  const _OnboardingFrame({
    required this.step,
    required this.children,
    required this.footer,
    required this.onBack,
  });
  final int step;
  final List<Widget> children;
  final Widget footer;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: footer,
      ),
    ),
    body: SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Geri',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 12),
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: i <= step ? AppColors.accent : AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    ),
  );
}

class _Intro extends StatelessWidget {
  const _Intro({
    required this.step,
    required this.title,
    required this.subtitle,
  });
  final int step;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Adım $step / 3',
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -.7,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.secondaryText),
      ),
    ],
  );
}

class _ExamOption extends StatelessWidget {
  const _ExamOption({
    required this.exam,
    required this.selected,
    required this.onTap,
  });
  final ExamChoice exam;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final days = _days(exam.examDate);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.line,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.accent : AppColors.line,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _examTitle(exam),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      exam.exam.name.contains('KPSS')
                          ? 'Genel Yetenek – Genel Kültür'
                          : exam.exam.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (exam.examDate == null)
                      Text(
                        examDateLabel(
                          null,
                          estimatedDate: exam.estimatedDate,
                          year: exam.year,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (days != null && days >= 0) ...[
                const SizedBox(width: 10),
                Column(
                  children: [
                    Text(
                      '$days',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    Text('gün', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.text,
    required this.color,
    required this.background,
  });
  final String text;
  final Color color, background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.accent,
    this.onChange,
  });
  final IconData icon;
  final String label, value;
  final Color color;
  final VoidCallback? onChange;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
      if (onChange != null)
        TextButton(onPressed: onChange, child: const Text('Değiştir')),
    ],
  );
}

int? _days(DateTime? date) => date == null
    ? null
    : DateUtils.dateOnly(date)
          .difference(DateUtils.dateOnly(DateTime.now()))
          .inDays;
String _examTitle(ExamChoice exam) =>
    '${exam.exam.name.split('(').first.trim()} ${exam.year}';
String _examDate(ExamChoice exam) {
  final date = exam.examDate;
  if (date == null) {
    return examDateLabel(
      null,
      estimatedDate: exam.estimatedDate,
      year: exam.year,
    );
  }
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
  return '${date.day} ${months[date.month - 1]} ${date.year} · ${_days(date)} gün';
}
