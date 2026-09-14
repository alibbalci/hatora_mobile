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
    Routes.statistics,
    Routes.notebook,
    Routes.more,
  ];
  @override
  Widget build(BuildContext context) {
    final index = paths.indexOf(location).clamp(0, paths.length - 1);
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => context.go(paths[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Ana Sayfa',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'İstatistik',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded),
              label: 'Sorularım',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
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
