import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/startup_animation.dart';
import '../domain/progress_models.dart';

final dailyCelebrationGateProvider =
    NotifierProvider<DailyCelebrationGate, Set<String>>(
      DailyCelebrationGate.new,
    );

class DailyCelebrationGate extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  bool claim(String userId, DailyProgress today) {
    if (!today.goalCompleted ||
        today.effectiveReviewGoal <= 0 ||
        today.reviewsCompleted <= 0) {
      return false;
    }
    final date = today.activityDate,
        key = '$userId:${date.year}-${date.month}-${date.day}';
    if (state.contains(key)) return false;
    state = {...state, key};
    return true;
  }
}

class DailyGoalCompleteScreen extends ConsumerStatefulWidget {
  const DailyGoalCompleteScreen({
    super.key,
    required this.progress,
    required this.onFinish,
    required this.onMore,
  });
  final UserProgress progress;
  final VoidCallback onFinish, onMore;
  @override
  ConsumerState<DailyGoalCompleteScreen> createState() =>
      _DailyGoalCompleteScreenState();
}

class _DailyGoalCompleteScreenState
    extends ConsumerState<DailyGoalCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  @override
  void initState() {
    super.initState();
    animation.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      animation.value = 1;
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress,
        today = p.today,
        study = ref.watch(dashboardViewModelProvider).summary?.study;
    return Scaffold(
      backgroundColor: AppColors.accent,
      body: Stack(
        children: [
          const Positioned(right: -70, top: -50, child: _DecorativeCircle()),
          const Positioned(left: -90, bottom: 120, child: _DecorativeCircle()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 38, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (c.maxHeight - 62).clamp(0, double.infinity),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: AnimatedBuilder(
                            animation: animation,
                            builder: (context, _) {
                              final v = animation.value,
                                  ring =
                                      ((today.reviewsCompleted - 1) /
                                              today.effectiveReviewGoal)
                                          .clamp(0.0, 1.0) +
                                      (1 -
                                              ((today.reviewsCompleted - 1) /
                                                      today.effectiveReviewGoal)
                                                  .clamp(0.0, 1.0)) *
                                          (v / .3).clamp(0.0, 1.0);
                              return SizedBox(
                                width: 176,
                                height: 176,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox.expand(
                                      child: CircularProgressIndicator(
                                        value: ring,
                                        strokeWidth: 13,
                                        color: AppColors.surface,
                                        backgroundColor: AppColors.surface
                                            .withValues(alpha: .16),
                                      ),
                                    ),
                                    if (v < .4)
                                      Text(
                                        '${v < .2 ? today.reviewsCompleted - 1 : today.reviewsCompleted} / ${today.effectiveReviewGoal}',
                                        style: const TextStyle(
                                          color: AppColors.surface,
                                          fontSize: 34,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        width: 82,
                                        height: 82,
                                        child: HatoraAnimatedMark(
                                          progress: ((v - .4) / .4).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 26),
                        _appear(
                          .3,
                          child: Column(
                            children: [
                              Text(
                                'Bugünün hedefi tamam',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppColors.surface,
                                      fontSize: 27,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${today.reviewsCompleted} soruyu yeniden çözdün. Yarın daha güçlü başlayacaksın.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFDCD8FF),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _appear(
                          .45,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Color(0xFFFFB36B),
                                      size: 30,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${p.currentStreak} gün',
                                            style: const TextStyle(
                                              color: AppColors.surface,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Text(
                                            'günlük seri',
                                            style: TextStyle(
                                              color: Color(0xFFC9C3FF),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface.withValues(
                                          alpha: .16,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'Rekor: ${p.longestStreak}',
                                        style: const TextStyle(
                                          color: AppColors.surface,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    for (var i = 0; i < 7; i++)
                                      Expanded(
                                        child: Builder(
                                          builder: (context) {
                                            final monday =
                                                DateTime(
                                                  today.activityDate.year,
                                                  today.activityDate.month,
                                                  today.activityDate.day,
                                                ).subtract(
                                                  Duration(
                                                    days:
                                                        today
                                                            .activityDate
                                                            .weekday -
                                                        1,
                                                  ),
                                                );
                                            final date = monday.add(
                                              Duration(days: i),
                                            );
                                            final isToday = DateUtils.isSameDay(
                                                  date,
                                                  today.activityDate,
                                                ),
                                                done =
                                                    isToday ||
                                                    (study?.weekDays.any(
                                                          (d) =>
                                                              DateUtils.isSameDay(
                                                                d.date,
                                                                date,
                                                              ) &&
                                                              d.goalCompleted,
                                                        ) ??
                                                        false);
                                            return Column(
                                              children: [
                                                Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isToday
                                                        ? const Color(
                                                            0xFF2EE6A8,
                                                          )
                                                        : done
                                                        ? AppColors.surface
                                                        : AppColors.surface
                                                              .withValues(
                                                                alpha: .14,
                                                              ),
                                                  ),
                                                  child: done
                                                      ? Icon(
                                                          Icons.check_rounded,
                                                          size: 18,
                                                          color: isToday
                                                              ? const Color(
                                                                  0xFF0B4D39,
                                                                )
                                                              : AppColors
                                                                    .accent,
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  [
                                                    'Pt',
                                                    'Sa',
                                                    'Ça',
                                                    'Pe',
                                                    'Cu',
                                                    'Ct',
                                                    'Pz',
                                                  ][i],
                                                  style: TextStyle(
                                                    color: isToday
                                                        ? AppColors.surface
                                                        : const Color(
                                                            0xFFC9C3FF,
                                                          ),
                                                    fontSize: 11,
                                                    fontWeight: isToday
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Spacer(),
                        _appear(
                          .6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: AppColors.accent,
                                  minimumSize: const Size(0, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: widget.onFinish,
                                child: const Text('Harika, bitir'),
                              ),
                              TextButton(
                                onPressed: widget.onMore,
                                child: const Text(
                                  'Biraz daha tekrar et',
                                  style: TextStyle(color: Color(0xFFDCD8FF)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) =>
                    CustomPaint(painter: _GoalConfetti(animation.value)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appear(double start, {required Widget child}) => FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        (start + .25).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    ),
    child: child,
  );
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle();
  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    height: 220,
    decoration: const BoxDecoration(
      color: Color(0xFF5A4BEE),
      shape: BoxShape.circle,
    ),
  );
}

class _GoalConfetti extends CustomPainter {
  const _GoalConfetti(this.value);
  final double value;
  @override
  void paint(Canvas c, Size s) {
    if (value < .35 || value >= 1) return;
    final v = (value - .35) / .65;
    for (var i = 0; i < 45; i++) {
      final x = (i * 71 % s.width) + math.sin(i + v * 4) * 20,
          y = -20 + v * (s.height + 60) - (i % 5) * 26;
      c.save();
      c.translate(x, y);
      c.rotate(i + v * 6);
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -5, 6, 10),
          const Radius.circular(2),
        ),
        Paint()
          ..color = [
            AppColors.surface,
            const Color(0xFF2EE6A8),
            const Color(0xFFFF6B5B),
            const Color(0xFFFFA36B),
            const Color(0xFFB9B0FF),
          ][i % 5].withValues(alpha: (1 - v).clamp(0.0, 1.0)),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_GoalConfetti old) => old.value != value;
}
