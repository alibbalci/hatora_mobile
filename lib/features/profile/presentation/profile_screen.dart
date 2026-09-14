import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../progress/presentation/progress_widgets.dart';
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
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: s.overview == null
            ? (s.phase == ProfilePhase.loading
                  ? ListView(
                      children: const [
                        LoadingView(label: 'Profilin yükleniyor…'),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        ErrorView(error: s.failure!, onRetry: vm.retry),
                      ],
                    ))
            : PageBody(
                children: [
                  _Identity(
                    name: s.overview!.user.displayName,
                    email: s.overview!.user.email,
                  ),
                  if (s.failure != null) ErrorView(error: s.failure!),
                  const SectionHeader('İlerleme'),
                  ProgressOverview(progress: s.overview!.progress),
                  const SectionHeader('Çalışma profili'),
                  _InfoRow(
                    icon: Icons.school_outlined,
                    title: 'Aktif sınav',
                    value:
                        s.overview!.study.examDisplay ??
                        'Aktif sınav bulunamadı',
                  ),
                  _ActionRow(
                    icon: Icons.flag_outlined,
                    title: 'Günlük tekrar hedefi',
                    value: '${s.overview!.study.dailyReviewGoal} soru',
                    onTap: s.phase == ProfilePhase.saving
                        ? null
                        : () => _goal(
                            context,
                            vm,
                            s.overview!.study.dailyReviewGoal,
                          ),
                  ),
                  const SectionHeader('Hesap bilgileri'),
                  _ActionRow(
                    icon: Icons.badge_outlined,
                    title: 'Görünen ad',
                    value: s.overview!.user.displayName,
                    onTap: s.phase == ProfilePhase.saving
                        ? null
                        : () =>
                              _name(context, vm, s.overview!.user.displayName),
                  ),
                  if (s.overview!.user.createdAt != null)
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      title: 'Üyelik tarihi',
                      value: _date(s.overview!.user.createdAt!),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: auth.busy ? null : () => _logout(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.logout),
                    label: Text(auth.busy ? 'Çıkış yapılıyor…' : 'Çıkış Yap'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _name(
    BuildContext c,
    ProfileViewModel vm,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('Görünen adı değiştir'),
        content: TextField(
          controller: controller,
          maxLength: 100,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await vm.updateName(value);
  }

  Future<void> _goal(BuildContext c, ProfileViewModel vm, int current) async {
    final controller = TextEditingController(text: '$current');
    final value = await showDialog<int>(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('Günlük tekrar hedefi'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(helperText: '1–200 soru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, int.tryParse(controller.text)),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
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
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authViewModelProvider.notifier).signOut();
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.name, required this.email});
  final String name, email;
  @override
  Widget build(BuildContext c) => Column(
    children: [
      CircleAvatar(
        radius: 38,
        backgroundColor: AppColors.accentSoft,
        foregroundColor: AppColors.accent,
        child: Text(
          _initials(name),
          style: Theme.of(c).textTheme.titleLarge
              ?.copyWith(color: AppColors.accent),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        name,
        textAlign: TextAlign.center,
        style: Theme.of(c).textTheme.titleLarge,
      ),
      if (email.isNotEmpty)
        Text(
          email,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.secondaryText),
        ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title, value;
  @override
  Widget build(BuildContext c) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });
  final IconData icon;
  final String title, value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext c) => Card(
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    ),
  );
}

String _initials(String name) {
  final p = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (p.isEmpty) return '?';
  return p.take(2).map((e) => e[0].toUpperCase()).join();
}

String _date(DateTime d) => '${d.day}.${d.month}.${d.year}';
