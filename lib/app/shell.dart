import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/widget/components.dart';
import 'providers.dart';
import 'routes.dart';
import '../features/question/presentation/my_questions_screens.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;
  static const paths = [
    Routes.home,
    Routes.plan,
    Routes.capture,
    Routes.statistics,
    Routes.notebook,
  ];
  @override
  Widget build(BuildContext context) {
    final index = paths.indexOf(location).clamp(0, paths.length - 1);
    return Scaffold(
      body: child,
      bottomNavigationBar: HatoraBottomBar(
        index: index,
        onSelected: (i) {
          if (i == 2) {
            context.push(Routes.capture);
          } else {
            context.go(paths[i]);
          }
        },
      ),
    );
  }
}

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.message,
  });
  final String title, message;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: PageBody(
      children: [EmptyView(title: 'Yakında', message: message)],
    ),
  );
}

class NotebookScreen extends MyQuestionsScreen {
  const NotebookScreen({super.key});
}

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Daha fazla')),
      body: PageBody(
        children: [
          Text(
            auth.user?.displayName ?? '',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.drawing),
            icon: const Icon(Icons.draw_outlined),
            label: const Text('Karalama alanı'),
          ),
          if (auth.failure != null) ErrorView(error: auth.failure!),
          HatoraPrimaryButton(
            label: 'Çıkış yap',
            busy: auth.busy,
            onPressed: ref.read(authViewModelProvider.notifier).signOut,
          ),
        ],
      ),
    );
  }
}

class _CaptureIcon extends StatelessWidget {
  const _CaptureIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.add_rounded, color: AppColors.surface, size: 28),
  );
}

class HatoraBottomBar extends StatelessWidget {
  const HatoraBottomBar({
    super.key,
    required this.index,
    required this.onSelected,
  });
  final int index;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      border: Border.all(color: AppColors.line),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            for (var i = 0; i < 5; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i != 2 && index == i,
                  label: [
                    'Ana sayfa',
                    'Plan',
                    'Soru ekle',
                    'İstatistik',
                    'Sorularım',
                  ][i],
                  child: Tooltip(
                    message: [
                      'Ana sayfa',
                      'Plan',
                      'Soru ekle',
                      'İstatistik',
                      'Sorularım',
                    ][i],
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onSelected(i),
                      child: Center(
                        child: i == 2
                            ? const _CaptureIcon()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: index == i
                                          ? AppColors.accentSoft
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      [
                                        Icons.home_outlined,
                                        Icons.calendar_month_outlined,
                                        Icons.add_rounded,
                                        Icons.bar_chart_rounded,
                                        Icons.auto_stories_outlined,
                                      ][i],
                                      size: 23,
                                      color: index == i
                                          ? AppColors.accent
                                          : AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      'Ana sayfa',
                                      'Plan',
                                      '',
                                      'İstatistik',
                                      'Sorularım',
                                    ][i],
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: index == i
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: index == i
                                          ? AppColors.accent
                                          : AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
