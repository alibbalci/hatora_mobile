import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';

final startupGateProvider = NotifierProvider<StartupGate, bool>(
  StartupGate.new,
);

class StartupGate extends Notifier<bool> {
  @override
  bool build() => false;
  void finish() => state = true;
}

class HatoraStartupAnimation extends StatefulWidget {
  const HatoraStartupAnimation({super.key, required this.onFinished});
  final VoidCallback onFinished;
  @override
  State<HatoraStartupAnimation> createState() => _HatoraStartupAnimationState();
}

class _HatoraStartupAnimationState extends State<HatoraStartupAnimation>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  @override
  void initState() {
    super.initState();
    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) widget.onFinished();
    });
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.accent,
    body: SafeArea(
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final textProgress = Curves.easeOut.transform(
              ((controller.value - .45) / .15).clamp(0, 1),
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Hatora açılıyor',
                  image: true,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(painter: _DrawingLogo(controller.value)),
                  ),
                ),
                const SizedBox(height: 14),
                Opacity(
                  opacity: textProgress,
                  child: Transform.translate(
                    offset: Offset(0, 6 * (1 - textProgress)),
                    child: const Column(
                      children: [
                        Text(
                          'hatora',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1,
                            color: AppColors.surface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hatalarını rotaya dönüştür',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: Color(0xFFDCD8FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _DrawingLogo extends CustomPainter {
  const _DrawingLogo(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 120);
    final p = Paint()..color = AppColors.surface;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 16, 22, 88),
        const Radius.circular(11),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 16, 22, 88),
        const Radius.circular(11),
      ),
      p,
    );
    final path = Path()
      ..moveTo(33, 80)
      ..cubicTo(33, 60, 48, 58, 60, 60)
      ..cubicTo(72, 62, 80, 52, 89, 40);
    final metric = path.computeMetrics().first;
    final part = metric.extractPath(
      0,
      metric.length * Curves.easeInOut.transform((progress / .4).clamp(0, 1)),
    );
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 22
      ..color = AppColors.accent;
    canvas.drawPath(part, p);
    p
      ..strokeWidth = 12
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFFF6B5B), Color(0xFFFFA36B), Color(0xFF2EE6A8)],
      ).createShader(const Rect.fromLTRB(30, 35, 94, 84));
    canvas.drawPath(part, p);
    p.shader = null;
    final arrow = ((progress - .35) / .2).clamp(0, 1).toDouble();
    if (arrow > 0) {
      canvas.save();
      canvas.translate(91, 40);
      final scale = .6 + Curves.easeOutBack.transform(arrow) * .4;
      canvas.scale(scale);
      canvas.translate(-91, -40);
      final a = Path()
        ..moveTo(80.5, 38.4)
        ..lineTo(91.4, 36.8)
        ..lineTo(93, 47.7);
      p
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 22
        ..color = AppColors.accent.withValues(alpha: arrow);
      canvas.drawPath(a, p);
      p
        ..strokeWidth = 12
        ..color = const Color(0xFF2EE6A8).withValues(alpha: arrow);
      canvas.drawPath(a, p);
      canvas.restore();
    }
    p
      ..style = PaintingStyle.fill
      ..color = AppColors.accent;
    canvas.drawCircle(const Offset(33, 80), 12.5, p);
    canvas.drawCircle(
      const Offset(33, 80),
      10,
      p..color = const Color(0xFFFF6B5B),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DrawingLogo oldDelegate) =>
      progress != oldDelegate.progress;
}

class HomeLoadingSkeleton extends StatefulWidget {
  const HomeLoadingSkeleton({super.key});
  @override
  State<HomeLoadingSkeleton> createState() => _HomeLoadingSkeletonState();
}

class _HomeLoadingSkeletonState extends State<HomeLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget box({
    double? width,
    required double height,
    double radius = 8,
    bool dark = false,
    Widget? child,
  }) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: dark ? const Color(0xFF26234F) : const Color(0xFFE9E8F2),
              ),
            ),
            ?child,
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, c) => Transform.translate(
                  offset: Offset((controller.value * 2 - 1) * c.maxWidth, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: dark ? .08 : .55),
                          Colors.transparent,
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
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Ana sayfa yükleniyor',
    liveRegion: true,
    child: ExcludeSemantics(
      child: Column(
        children: [
          Row(
            children: [
              box(width: 50, height: 50, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(width: 110, height: 12),
                    const SizedBox(height: 8),
                    box(width: 155, height: 20),
                  ],
                ),
              ),
              box(width: 42, height: 42, radius: 30),
              const SizedBox(width: 10),
              box(width: 42, height: 42, radius: 30),
            ],
          ),
          const SizedBox(height: 22),
          box(
            height: 168,
            radius: 30,
            dark: true,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(145, 12),
                  const SizedBox(height: 14),
                  _line(85, 48),
                  const SizedBox(height: 16),
                  _line(180, 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          box(height: 300, radius: 26),
          const SizedBox(height: 18),
          box(height: 100, radius: 26),
        ],
      ),
    ),
  );
  Widget _line(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFF34306A),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class HomeArrival extends StatelessWidget {
  const HomeArrival({super.key, required this.child, this.order = 0});
  final Widget child;
  final int order;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = order * 80;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + delay),
      curve: Interval(delay / (400 + delay), 1, curve: Curves.easeOut),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class HatoraAnimatedMark extends StatelessWidget {
  const HatoraAnimatedMark({super.key, required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DrawingLogo(progress));
}
