import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../../core/widget/reference_widgets.dart';
import '../../question/domain/question.dart';
import '../../question/presentation/question_screens.dart' show reasonLabels;
import '../domain/review_models.dart';

class QuestionLearnedMoment extends ConsumerStatefulWidget {
  const QuestionLearnedMoment({
    super.key,
    required this.item,
    required this.result,
    required this.answerCount,
    required this.onNext,
    required this.onClose,
    this.image,
  });
  final NextReviewItem item;
  final AnswerResult result;
  final int answerCount;
  final Uint8List? image;
  final VoidCallback onNext, onClose;
  @override
  ConsumerState<QuestionLearnedMoment> createState() =>
      _QuestionLearnedMomentState();
}

class _QuestionLearnedMomentState extends ConsumerState<QuestionLearnedMoment>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
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
    final item = widget.item, r = widget.result;
    final question = ref
        .watch(_learnedQuestionProvider(r.questionId))
        .asData
        ?.value;
    final created = question?.createdAt;
    final panel = CurvedAnimation(
      parent: animation,
      curve: const Interval(.55, 1, curve: Curves.easeOutCubic),
    );
    return Scaffold(
      bottomNavigationBar: SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(panel),
        child: FadeTransition(
          opacity: panel,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.successSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: CustomPaint(painter: LearnedRouteBadge()),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Öğrenildi',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Hatanı rotaya\ndönüştürdün',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(height: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          context,
                          '${r.newStage} aşama',
                          'tamamlandı',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metric(
                          context,
                          created == null
                              ? '—'
                              : '${created.day} ${_month(created.month)}',
                          'deftere eklendi',
                        ),
                      ),
                    ],
                  ),
                  HatoraPrimaryButton(
                    solidColor: AppColors.accent,
                    label: r.sessionCompleted
                        ? 'Tekrarı tamamla'
                        : 'Sonraki soru',
                    onPressed: widget.onNext,
                  ),
                  Text(
                    'Bu soru öğrenilen sorularına taşındı.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: PageBody(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Oturumdan çık',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: item.totalItems == 0
                        ? 0
                        : (item.position / item.totalItems).clamp(0, 1),
                    minHeight: 7,
                    color: AppColors.accent,
                    backgroundColor: AppColors.line,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${item.position} / ${item.totalItems}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) => Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: animation.value > .5
                    ? const Color(0xFFF3FDF9)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: animation.value > .5
                      ? const Color(0xFF2EE6A8)
                      : AppColors.line,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 50,
                    child: CustomPaint(
                      painter: _LearningTrail(animation.value),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.subjectName,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              item.topicName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      if (r.mistakeReason != null)
                        Flexible(
                          child: ReferenceTag(
                            label: reasonLabels[r.mistakeReason]!,
                            color: AppColors.secondaryText,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (widget.image != null)
                    QuestionImageCard(
                      bytes: widget.image!,
                      height: 180,
                      bottomMargin: 0,
                      backgroundColor: const Color(0xFFFBFBF8),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 0; i < widget.answerCount; i++) ...[
                        if (i > 0) const SizedBox(width: 7),
                        Expanded(
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  r.correctAnswer == String.fromCharCode(65 + i)
                                  ? AppColors.success
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    r.correctAnswer ==
                                        String.fromCharCode(65 + i)
                                    ? AppColors.success
                                    : AppColors.line,
                              ),
                            ),
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    r.correctAnswer ==
                                        String.fromCharCode(65 + i)
                                    ? AppColors.surface
                                    : AppColors.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String value, String label) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleSmall),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    ),
  );
}

final _learnedQuestionProvider = FutureProvider.autoDispose
    .family<Question, String>(
      (ref, id) => ref.read(questionRepositoryProvider).getQuestion(id),
    );
String _month(int month) => [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
][month - 1];

class LearnedRouteBadge extends CustomPainter {
  const LearnedRouteBadge();
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 34, s.height / 34);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.success
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(8, 24)
      ..cubicTo(12, 24, 13, 16, 17, 16)
      ..cubicTo(20, 16, 21, 13, 24, 10);
    c.drawPath(path, p);
    c.drawPath(
      Path()
        ..moveTo(19, 9.5)
        ..lineTo(24.5, 9)
        ..lineTo(24, 14.5),
      p,
    );
    c.drawCircle(
      const Offset(8, 24),
      2.5,
      p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFF6B5B),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LearningTrail extends CustomPainter {
  const _LearningTrail(this.value);
  final double value;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 280, size.height / 50);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..color = AppColors.line;
    final path = Path()
          ..moveTo(22, 28)
          ..cubicTo(70, 28, 92, 10, 140, 18)
          ..cubicTo(180, 26, 222, 36, 254, 15),
        m = path.computeMetrics().first;
    for (double d = 0; d < m.length; d += 9) {
      final t = m.getTangentForOffset(d);
      if (t != null) {
        c.drawCircle(t.position, 1.4, p..style = PaintingStyle.fill);
      }
    }
    final progress = (value / .6).clamp(0.0, 1.0),
        part = m.extractPath(0, m.length * progress);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6B5B), Color(0xFFFFA36B), Color(0xFF2EE6A8)],
      ).createShader(const Rect.fromLTRB(22, 0, 256, 50));
    c.drawPath(part, p);
    p.shader = null;
    if (progress < 1) {
      final point =
          m.getTangentForOffset(m.length * progress)?.position ??
          const Offset(22, 28);
      c.drawCircle(
        point,
        10,
        p
          ..style = PaintingStyle.fill
          ..color = AppColors.surface,
      );
      c.drawCircle(point, 8, p..color = const Color(0xFFFF6B5B));
    } else {
      c.drawPath(
        Path()
          ..moveTo(244, 10)
          ..lineTo(256, 13.5)
          ..lineTo(248, 23),
        p
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF2EE6A8),
      );
    }
    if (value > .6 && value < 1) {
      final t = (value - .6) / .4;
      for (var i = 0; i < 18; i++) {
        final angle = i * 2.4, dist = 8 + t * (18 + (i % 4) * 9);
        final x = 254 + math.cos(angle) * dist,
            y = 15 + math.sin(angle) * dist + t * t * 30;
        c.save();
        c.translate(x, y);
        c.rotate(angle + t * 2);
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-2, -4, 4, 8),
            const Radius.circular(1),
          ),
          p
            ..style = PaintingStyle.fill
            ..color = [
              AppColors.accent,
              const Color(0xFF2EE6A8),
              const Color(0xFFFF6B5B),
              const Color(0xFFFFA36B),
            ][i % 4].withValues(alpha: 1 - t),
        );
        c.restore();
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_LearningTrail oldDelegate) => oldDelegate.value != value;
}
