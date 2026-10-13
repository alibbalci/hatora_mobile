import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widget/components.dart';
import '../core/widget/startup_animation.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/auth_view_model.dart';
import '../features/catalog/domain/catalog.dart';
import '../features/catalog/presentation/topic_picker_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/plan/presentation/plan_screen.dart';
import '../features/onboarding/presentation/onboarding_screens.dart';
import '../features/question/domain/question.dart';
import '../features/question/presentation/question_camera_screen.dart';
import '../features/question/presentation/question_screens.dart';
import '../features/question/presentation/my_questions_screens.dart';
import '../features/review/domain/review_models.dart';
import '../features/review/presentation/review_session_screen.dart';
import '../features/review/presentation/review_setup_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../shared/drawing/drawing_screen.dart';
import 'providers.dart';
import 'routes.dart';
import 'shell.dart';

String? sessionRedirect(
  AuthState auth,
  String location, {
  required bool hasExamSelection,
}) {
  final onboarding = location.startsWith(Routes.exams);
  if (auth.status == AuthStatus.restoring) {
    return location == Routes.splash ? null : Routes.splash;
  }
  if (auth.status == AuthStatus.guest) {
    if (onboarding || location == Routes.auth || location == Routes.welcome) {
      return null;
    }
    return Routes.welcome;
  }
  if (auth.user?.onboardingCompleted != true) {
    if (onboarding) return null;
    return hasExamSelection ? Routes.value : Routes.exams;
  }
  if (onboarding ||
      location == Routes.welcome ||
      location == Routes.auth ||
      location == Routes.splash) {
    return Routes.home;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(startupGateProvider, (_, _) => refresh.update());
  ref.listen(authViewModelProvider, (previous, next) {
    if (previous?.user?.id != next.user?.id) {
      ref.invalidate(dashboardViewModelProvider);
      ref.invalidate(statisticsViewModelProvider);
      ref.invalidate(exportViewModelProvider);
      ref.invalidate(captureViewModelProvider);
      ref.invalidate(confirmViewModelProvider);
      ref.invalidate(reviewSetupViewModelProvider);
      ref.invalidate(reviewSessionViewModelProvider);
      ref.invalidate(reviewImageProvider);
      ref.invalidate(myQuestionsViewModelProvider);
      ref.invalidate(questionDetailViewModelProvider);
      ref.invalidate(questionEditViewModelProvider);
      ref.invalidate(questionImageProvider);
      ref.invalidate(progressViewModelProvider);
      ref.invalidate(profileViewModelProvider);
      ref.invalidate(examScheduleProvider);
      if (previous?.user != null) ref.invalidate(onboardingViewModelProvider);
    }
    refresh.update();
  });
  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      if (!ref.read(startupGateProvider)) {
        return state.uri.path == Routes.splash ? null : Routes.splash;
      }
      final auth = ref.read(authViewModelProvider);
      final selected =
          ref.read(onboardingViewModelProvider).selectedExam != null;
      final redirect = sessionRedirect(
        auth,
        state.uri.path,
        hasExamSelection: selected,
      );
      if (redirect != null) return redirect;
      if ((state.uri.path == Routes.goal || state.uri.path == Routes.value) &&
          !selected) {
        return Routes.exams;
      }
      if (state.uri.path == Routes.confirm &&
          state.extra is! ConfirmationSeed) {
        return Routes.capture;
      }
      if (state.uri.path == Routes.topics && state.extra is! List<Topic>) {
        return Routes.capture;
      }
      if (state.uri.path.startsWith('/review/session/') &&
          state.extra is! ReviewSessionContext) {
        return Routes.review;
      }
      if (state.uri.path.startsWith('/questions/')) {
        final id = state.pathParameters['id'];
        if (id == null || !_uuid.hasMatch(id)) return Routes.myQuestions;
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: PageBody(
        children: [
          const EmptyView(
            title: 'Sayfa bulunamadı',
            message: 'Bu bağlantı artık kullanılamıyor.',
          ),
          HatoraPrimaryButton(
            label: 'Başlangıca dön',
            onPressed: () => context.go(Routes.splash),
          ),
        ],
      ),
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const _SessionScreen()),
      GoRoute(
        path: Routes.exams,
        builder: (_, _) => const ExamSelectionScreen(),
      ),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.goal, builder: (_, _) => const DailyGoalScreen()),
      GoRoute(
        path: Routes.value,
        builder: (_, _) => const ValuePropositionScreen(),
      ),
      GoRoute(
        path: Routes.auth,
        builder: (_, s) => AuthScreen(
          registerInitially: s.uri.queryParameters['register'] == '1',
        ),
      ),
      ShellRoute(
        builder: (_, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
          GoRoute(path: Routes.plan, builder: (_, _) => const PlanScreen()),
          GoRoute(
            path: Routes.statistics,
            builder: (_, _) => const StatisticsScreen(),
          ),
          GoRoute(
            path: Routes.notebook,
            builder: (_, _) => const NotebookScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            builder: (_, _) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.capture,
        builder: (_, _) => const QuestionCaptureScreen(),
      ),
      GoRoute(
        path: Routes.camera,
        pageBuilder: (_, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const QuestionCameraScreen(),
        ),
      ),
      GoRoute(
        path: Routes.confirm,
        builder: (_, state) =>
            QuestionConfirmScreen(seed: state.extra! as ConfirmationSeed),
      ),
      GoRoute(
        path: Routes.topics,
        builder: (_, state) =>
            TopicPickerScreen(topics: state.extra! as List<Topic>),
      ),
      GoRoute(path: Routes.drawing, builder: (_, _) => const DrawingScreen()),
      GoRoute(
        path: Routes.review,
        builder: (_, _) => const ReviewSetupScreen(),
      ),
      GoRoute(
        path: Routes.reviewSessionPattern,
        builder: (_, state) =>
            ReviewSessionScreen(session: state.extra! as ReviewSessionContext),
      ),
      GoRoute(
        path: Routes.questionDetailPattern,
        builder: (_, state) =>
            QuestionDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.questionEditPattern,
        builder: (_, state) =>
            QuestionEditScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _RouterRefresh extends ChangeNotifier {
  void update() => notifyListeners();
}

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

class _SessionScreen extends ConsumerWidget {
  const _SessionScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authViewModelProvider);
    final startupDone = ref.watch(startupGateProvider);
    if (!startupDone ||
        (state.status == AuthStatus.restoring && state.failure == null)) {
      return HatoraStartupAnimation(
        onFinished: () => ref.read(startupGateProvider.notifier).finish(),
      );
    }
    return Scaffold(
      body: PageBody(
        children: [
          const SizedBox(height: 80),
          Text('Hatora', style: Theme.of(context).textTheme.headlineMedium),
          if (state.failure == null)
            const LoadingView(label: 'Oturumun açılıyor…')
          else
            ErrorView(
              error: state.failure!,
              onRetry: ref.read(authViewModelProvider.notifier).restore,
            ),
        ],
      ),
    );
  }
}
