import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../domain/question.dart';
import 'question_capture_view_model.dart';

/// These are timing estimates, not reports from the analysis service.
double estimatedAnalysisProgress(Duration elapsed) {
  final seconds = elapsed.inMilliseconds / 1000;
  if (seconds < 2) return seconds / 2 * .3;
  if (seconds < 4) return .3 + (seconds - 2) / 2 * .32;
  return (.62 + (seconds - 4) / 4 * .28).clamp(.62, .90);
}

class QuestionAnalysisScreen extends ConsumerStatefulWidget {
  const QuestionAnalysisScreen({
    super.key,
    required this.state,
    required this.onCancel,
    required this.onRetry,
    required this.onNewImage,
    this.onContinue,
  });
  final CaptureState state;
  final VoidCallback onCancel, onRetry, onNewImage;
  final VoidCallback? onContinue;
  @override
  ConsumerState<QuestionAnalysisScreen> createState() =>
      _QuestionAnalysisScreenState();
}

class _QuestionAnalysisScreenState extends ConsumerState<QuestionAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  Timer? timer;
  Duration elapsed = Duration.zero;
  bool ready = false;
  bool get failed =>
      widget.state.failure != null ||
      widget.state.analysis?.manualSelectionRequired == true ||
      widget.state.analysis?.status == AnalysisStatus.failed;
  @override
  void initState() {
    super.initState();
    progress.addListener(() {
      if (mounted) setState(() {});
    });
    _sync();
  }

  @override
  void didUpdateWidget(QuestionAnalysisScreen old) {
    super.didUpdateWidget(old);
    if (old.state.phase != widget.state.phase) _sync();
  }

  void _sync() {
    timer?.cancel();
    ready = false;
    if (widget.state.phase == CapturePhase.analyzing) {
      elapsed = Duration.zero;
      progress.value = 0;
      timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (!mounted) return;
        setState(() => elapsed = Duration(milliseconds: t.tick * 100));
        progress.value = estimatedAnalysisProgress(elapsed);
      });
    } else if (failed) {
      ready = true;
      progress.value = .45;
    } else if (widget.state.canContinue) {
      progress.animateTo(1, curve: Curves.easeOut).whenComplete(() {
        if (mounted && widget.state.canContinue && !widget.state.busy) {
          setState(() => ready = true);
        }
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = ready && !failed
        ? 3
        : widget.state.canContinue && !failed
        ? (progress.value < .3
              ? 0
              : progress.value < .62
              ? 1
              : 2)
        : elapsed.inSeconds < 2
        ? 0
        : elapsed.inSeconds < 4
        ? 1
        : 2;
    final analysis = widget.state.analysis;
    final catalog = analysis == null
        ? null
        : ref.watch(_analysisCatalogProvider).asData?.value;
    final topic = catalog?.topics
        .where((t) => t.id == analysis?.suggestedTopicId)
        .firstOrNull;
    final title = failed
        ? (widget.state.failure != null
              ? 'Yükleme tamamlanamadı'
              : 'Konuyu bulamadık')
        : ready
        ? 'Buldum'
        : step == 0
        ? 'Fotoğrafı yüklüyoruz'
        : step == 1
        ? 'Sorunu okuyoruz'
        : 'Konusunu buluyoruz';
    final subtitle = failed
        ? (widget.state.failure?.message ??
              'AI bir konu önerisi hazırlayamadı. Konuyu kendin seçerek devam edebilirsin.')
        : ready
        ? 'Kontrol edip kaydetmeye geçiyoruz'
        : elapsed.inSeconds >= 15
        ? 'Biraz uzun sürüyor, bekliyoruz…'
        : step == 0
        ? 'Fotoğraf hazırlanıyor'
        : step == 1
        ? 'Rakamlar ve şıklar tanınıyor'
        : 'Ders ve konu eşleştiriliyor';
    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          child: failed
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.state.canContinue)
                      HatoraPrimaryButton(
                        solidColor: AppColors.accent,
                        label: 'Konuyu kendim seçeyim',
                        onPressed: widget.onContinue,
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onRetry,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Tekrar dene'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onNewImage,
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                            ),
                            label: const Text('Yeniden çek'),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : ready
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 64),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: widget.onContinue,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    topic == null
                        ? 'Öneriyi incele'
                        : '${topic.subjectName} · ${topic.name}',
                  ),
                )
              : TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Vazgeç'),
                ),
        ),
      ),
      body: PageBody(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Opacity(
              opacity: failed ? .55 : 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryInk,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: [
                    QuestionImageCard(
                      bytes: widget.state.image!.bytes,
                      height: 130,
                      bottomMargin: 0,
                      backgroundColor: const Color(0xFFFBFBF8),
                    ),
                    if (!failed && !ready && step == 1)
                      Positioned(
                        left: 8,
                        right: 8,
                        top: 15 + (elapsed.inMilliseconds % 2000) / 2000 * 105,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B7FFF),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) => Semantics(
                label: failed
                    ? 'Analiz tamamlanamadı'
                    : ready
                    ? 'Analiz tamamlandı'
                    : 'Analiz sürüyor',
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _AnalysisRoute(
                      progress.value,
                      complete: ready && !failed,
                      failed: failed,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (!failed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: i < step
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 22,
                                  )
                                : i == step
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accent,
                                  )
                                : const Icon(
                                    Icons.radio_button_unchecked,
                                    color: AppColors.line,
                                    size: 22,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              [
                                'Fotoğraf yükleniyor',
                                'Soru okunuyor',
                                'Ders ve konu bulunuyor',
                              ][i],
                              style: TextStyle(
                                fontSize: 14,
                                color: i == step
                                    ? AppColors.primaryInk
                                    : AppColors.secondaryText,
                                fontWeight: i == step
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (failed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Soruyu düz tutup iyi ışıkta tekrar çekmek genelde işe yarar.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

final _analysisCatalogProvider = FutureProvider.autoDispose((ref) async {
  final status = await ref.read(onboardingRepositoryProvider).status();
  return ref.read(catalogRepositoryProvider).questionCatalog(status.examId!);
});

class _AnalysisRoute extends CustomPainter {
  const _AnalysisRoute(
    this.progress, {
    required this.complete,
    required this.failed,
  });
  final double progress;
  final bool complete, failed;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 120, size.height / 120);
    final p = Paint()
      ..color = failed ? const Color(0xFFC9C5F5) : AppColors.accent;
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 16, 22, 88),
        const Radius.circular(11),
      ),
      p,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 16, 22, 88),
        const Radius.circular(11),
      ),
      p,
    );
    final path = Path()
          ..moveTo(33, 80)
          ..cubicTo(33, 60, 48, 58, 60, 60)
          ..cubicTo(72, 62, 80, 52, 89, 40),
        metric = path.computeMetrics().first;
    for (double d = 0; d < metric.length; d += 7) {
      final t = metric.getTangentForOffset(d);
      if (t != null) {
        c.drawCircle(t.position, 1.4, p..color = const Color(0xFFE2E0EF));
      }
    }
    final part = metric.extractPath(0, metric.length * progress);
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 22
      ..color = AppColors.background;
    c.drawPath(part, p);
    p.strokeWidth = 12;
    if (failed) {
      p.color = const Color(0xFFFF6B5B);
    } else {
      p.shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFFF6B5B), Color(0xFFFFA36B), Color(0xFF2EE6A8)],
      ).createShader(const Rect.fromLTRB(30, 35, 94, 84));
    }
    c.drawPath(part, p);
    p.shader = null;
    if (complete) {
      final arrow = Path()
        ..moveTo(80.5, 38.4)
        ..lineTo(91.4, 36.8)
        ..lineTo(93, 47.7);
      p
        ..strokeWidth = 22
        ..color = AppColors.background
        ..strokeJoin = StrokeJoin.round;
      c.drawPath(arrow, p);
      p
        ..strokeWidth = 12
        ..color = const Color(0xFF2EE6A8);
      c.drawPath(arrow, p);
    }
    p
      ..style = PaintingStyle.fill
      ..color = AppColors.background;
    c.drawCircle(const Offset(33, 80), 12.5, p);
    c.drawCircle(const Offset(33, 80), 10, p..color = const Color(0xFFFF6B5B));
    c.restore();
  }

  @override
  bool shouldRepaint(_AnalysisRoute old) =>
      old.progress != progress ||
      old.complete != complete ||
      old.failed != failed;
}
