import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../../core/widget/reference_widgets.dart';
import '../../../core/time/calendar_date.dart';
import '../../catalog/domain/catalog.dart';
import 'profile_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(profileViewModelProvider),
        vm = ref.read(profileViewModelProvider.notifier),
        auth = ref.watch(authViewModelProvider);
    ref.listen(profileViewModelProvider, (previous, next) {
      final user = next.overview?.user;
      if (user != null &&
          previous?.overview?.user.displayName != user.displayName) {
        ref.read(authViewModelProvider.notifier).synchronizeProfile(user);
      }
      if (previous?.overview != null &&
          previous!.overview!.study.examEditionId !=
              next.overview?.study.examEditionId) {
        ref.invalidate(dashboardViewModelProvider);
        ref.invalidate(onboardingViewModelProvider);
        ref.invalidate(statisticsViewModelProvider);
        ref.invalidate(reviewSetupViewModelProvider);
        ref.invalidate(reviewSessionViewModelProvider);
        ref.invalidate(myQuestionsViewModelProvider);
        ref.invalidate(exportViewModelProvider);
        ref.invalidate(captureViewModelProvider);
        ref.invalidate(confirmViewModelProvider);
        ref.invalidate(questionDetailViewModelProvider);
        ref.invalidate(questionEditViewModelProvider);
        ref.invalidate(examScheduleProvider);
      }
    });
    final data = s.overview;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profil'),
        leading: IconButton(
          tooltip: 'Geri',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.line),
          ),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        actions: [
          IconButton(
            tooltip: 'Profili düzenle',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.line),
            ),
            onPressed: data == null
                ? null
                : () => _name(context, vm, data.user.displayName),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: PageBody(
          children: [
            if (data == null)
              if (s.phase == ProfilePhase.loading)
                const LoadingView(label: 'Profilin yükleniyor…')
              else
                ErrorView(error: s.failure!, onRetry: vm.retry)
            else ...[
              if (s.failure != null) ErrorView(error: s.failure!),
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 47,
                            backgroundColor: AppColors.accentSoft,
                            foregroundColor: AppColors.accent,
                            child: Text(
                              _initials(data.user.displayName),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.levelGold,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              'Sv ${data.progress.level}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data.user.displayName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      data.user.email,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ReferenceCard(
                color: AppColors.accent,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'İlerleme',
                            style: TextStyle(
                              color: AppColors.surface.withValues(alpha: .7),
                            ),
                          ),
                        ),
                        ReferenceTag(
                          label: 'Bugün +${data.progress.today.xpEarned} XP',
                          icon: Icons.bolt_outlined,
                          color: AppColors.levelGold,
                          backgroundColor: AppColors.accent.withValues(
                            alpha: .25,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, c) {
                        final entries = [
                          (
                            '${data.progress.totalXp}',
                            'Toplam XP',
                            AppColors.warning,
                          ),
                          (
                            '${data.progress.currentStreak}',
                            'Günlük seri',
                            AppColors.error,
                          ),
                          (
                            '${data.progress.longestStreak}',
                            'En uzun seri',
                            AppColors.success,
                          ),
                        ];
                        return Wrap(
                          spacing: 12,
                          runSpacing: 16,
                          children: entries
                              .map(
                                (e) => SizedBox(
                                  width:
                                      MediaQuery.textScalerOf(context)
                                              .scale(14) >
                                          18
                                      ? c.maxWidth
                                      : (c.maxWidth - 24) / 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            e.$2 == 'Toplam XP'
                                                ? Icons.bolt_outlined
                                                : e.$2 == 'Günlük seri'
                                                ? Icons
                                                      .local_fire_department_outlined
                                                : Icons.emoji_events_outlined,
                                            color: e.$3,
                                            size: 19,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              e.$1,
                                              style: const TextStyle(
                                                color: AppColors.surface,
                                                fontSize: 25,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        e.$2,
                                        style: TextStyle(
                                          color: AppColors.surface.withValues(
                                            alpha: .65,
                                          ),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SectionHeader('Bugünün sonuçları'),
              ReferenceCard(
                child: LayoutBuilder(
                  builder: (context, c) => Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children:
                        [
                              (
                                data.progress.today.correctCount,
                                'Doğru',
                                AppColors.success,
                              ),
                              (
                                data.progress.today.wrongCount,
                                'Yanlış',
                                AppColors.error,
                              ),
                              (
                                data.progress.today.unsolvedCount,
                                'Boş',
                                AppColors.secondaryText,
                              ),
                              (
                                data.progress.today.questionsMastered,
                                'Öğrenilen',
                                AppColors.accent,
                              ),
                            ]
                            .map(
                              (e) => SizedBox(
                                width:
                                    MediaQuery.textScalerOf(context).scale(14) >
                                        18
                                    ? (c.maxWidth - 8) / 2
                                    : (c.maxWidth - 24) / 4,
                                child: Column(
                                  children: [
                                    Text(
                                      '${e.$1}',
                                      style: TextStyle(
                                        color: e.$3,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      e.$2,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
              const SectionHeader('Sınav ve hedef'),
              ReferenceCard(
                child: Column(
                  children: [
                    _ProfileRow(
                      icon: Icons.school_outlined,
                      label: 'Aktif sınav',
                      value: (data.study.examDisplay ?? 'Sınav seç')
                          .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
                          .replaceAll(' · ', ' '),
                      detail:
                          data.study.examDisplay?.contains('Genel Yetenek') ==
                              true
                          ? 'Genel Yetenek – Genel Kültür'
                          : null,
                      onTap: s.phase == ProfilePhase.saving
                          ? null
                          : () => _exam(context, ref, vm),
                    ),
                    const Divider(height: 26),
                    _ProfileRow(
                      icon: Icons.event_outlined,
                      label: 'Sınav tarihi',
                      value: data.study.examDate == null
                          ? 'Resmî tarih açıklanmadı'
                          : referenceDate(data.study.examDate!),
                      color: AppColors.accentEnd,
                      trailing: data.study.examDate == null
                          ? null
                          : ReferenceTag(
                              label:
                                  '${data.study.examDate!.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays} gün',
                              color: AppColors.warning,
                            ),
                    ),
                    const Divider(height: 26),
                    _ProfileRow(
                      icon: Icons.flag_outlined,
                      label: 'Günlük tekrar hedefi',
                      value: '${data.study.dailyReviewGoal} soru',
                      color: AppColors.success,
                      onTap: s.phase == ProfilePhase.saving
                          ? null
                          : () =>
                                _goal(context, vm, data.study.dailyReviewGoal),
                    ),
                  ],
                ),
              ),
              const SectionHeader('Hesap'),
              ReferenceCard(
                child: Column(
                  children: [
                    _ProfileRow(
                      icon: Icons.badge_outlined,
                      label: 'Görünen ad',
                      value: data.user.displayName,
                      onTap: s.phase == ProfilePhase.saving
                          ? null
                          : () => _name(context, vm, data.user.displayName),
                    ),
                    if (data.user.createdAt != null) ...[
                      const Divider(height: 26),
                      _ProfileRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Üyelik tarihi',
                        value: referenceDate(data.user.createdAt!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.line),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: auth.busy ? null : () => _logout(context, ref),
                icon: const Icon(Icons.logout_rounded),
                label: Text(auth.busy ? 'Çıkış yapılıyor…' : 'Çıkış yap'),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Hatora 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exam(
    BuildContext context,
    WidgetRef ref,
    ProfileViewModel vm,
  ) async {
    try {
      final choices = await ref.read(catalogRepositoryProvider).examChoices();
      if (!context.mounted) return;
      final value = await showModalBottomSheet<ExamChoice>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (c) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ReferenceHeader(title: 'Sınavını seç'),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: choices
                      .map(
                        (e) => ListTile(
                          title: Text(e.label),
                          subtitle: Text(
                            examDateLabel(
                              e.examDate,
                              estimatedDate: e.estimatedDate,
                              year: e.year,
                            ),
                          ),
                          onTap: () => Navigator.pop(c, e),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      );
      if (value != null) await vm.changeExam(value.editionId);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sınav listesi yüklenemedi. Tekrar dene.'),
          ),
        );
      }
    }
  }

  Future<void> _name(
    BuildContext c,
    ProfileViewModel vm,
    String current,
  ) async {
    final value = await showDialog<String>(
      context: c,
      builder: (_) => ReferenceInputDialog(
        title: 'Görünen adı değiştir',
        initialValue: current,
      ),
    );
    if (value != null) await vm.updateName(value);
  }

  Future<void> _goal(BuildContext c, ProfileViewModel vm, int current) async {
    final text = await showDialog<String>(
      context: c,
      builder: (_) => ReferenceInputDialog(
        title: 'Günlük tekrar hedefi',
        initialValue: '$current',
        numeric: true,
      ),
    );
    final value = int.tryParse(text ?? '');
    if (value != null) await vm.updateGoal(value);
  }

  Future<void> _logout(BuildContext c, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text('Bu cihazdaki oturumun kapatılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authViewModelProvider.notifier).signOut();
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    this.onTap,
    this.trailing,
    this.color = AppColors.accent,
  });
  final IconData icon;
  final String label, value;
  final String? detail;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color color;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(14),
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
              if (detail != null)
                Text(detail!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (trailing != null)
          trailing!
        else if (onTap != null)
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.secondaryText,
            size: 18,
          ),
      ],
    ),
  );
}

String _initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((s) => s.isNotEmpty)
    .take(2)
    .map((s) => String.fromCharCode(s.runes.first).toUpperCase())
    .join();
