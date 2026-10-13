import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../../core/widget/reference_widgets.dart';
import '../../catalog/domain/catalog.dart';
import '../domain/question.dart';
import 'question_capture_view_model.dart';
import 'question_analysis_screen.dart';
import 'question_saved_screen.dart';

class QuestionCaptureScreen extends ConsumerWidget {
  const QuestionCaptureScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(captureViewModelProvider);
    final vm = ref.read(captureViewModelProvider.notifier);
    if (state.image != null &&
        (state.phase == CapturePhase.analyzing ||
            state.analysis != null ||
            state.phase == CapturePhase.analysisFailure)) {
      return QuestionAnalysisScreen(
        state: state,
        onCancel: vm.cancelAnalysis,
        onRetry: vm.analyze,
        onNewImage: () => vm.selectImage(ImageOrigin.camera),
        onContinue: state.canContinue
            ? () => context.push(Routes.confirm, extra: state.seed)
            : null,
      );
    }
    final selected = state.image != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yanlış ekle'),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(5),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.line),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.home);
              }
            },
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 36).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CaptureSteps(selected: selected),
                    const SizedBox(height: 24),
                    Text(
                      selected
                          ? 'Fotoğraf hazır'
                          : 'Her hata, yeni bir\nöğrenme fırsatı.',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 27,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.7,
                          ),
                    ),
                    if (selected)
                      Text(
                        'Soru net görünüyorsa analize gönder.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.secondaryText),
                      ),
                    const SizedBox(height: 20),
                    if (selected)
                      Container(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                        decoration: BoxDecoration(
                          color: AppColors.primaryInk,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 28,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.surface,
                                  backgroundColor: AppColors.surface.withValues(
                                    alpha: .15,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontSize: 12),
                                ),
                                onPressed: state.busy
                                    ? null
                                    : () => _change(context, vm),
                                icon: const Icon(Icons.swap_horiz, size: 16),
                                label: const Text('Değiştir'),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Container(
                                color: const Color(0xFFFAFAF7),
                                child: QuestionImageCard(
                                  bytes: state.image!.bytes,
                                  height: 280,
                                  bottomMargin: 0,
                                  backgroundColor: const Color(0xFFFAFAF7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const CapturePhotoPlaceholder(),
                    const SizedBox(height: 16),
                    if (selected)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.successSoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_outlined,
                              color: AppColors.success,
                              size: 20,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Ders ve konu otomatik bulunacak',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Column(
                        children: [
                          CaptureTip('Sorunun tamamı karede olsun'),
                          CaptureTip('Net ve iyi ışıkta çek'),
                          CaptureTip('Her fotoğrafta tek soru'),
                        ],
                      ),
                    if (state.phase == CapturePhase.analyzing)
                      const LoadingView(
                        label: 'Ders ve konu önerisi hazırlanıyor…',
                      ),
                    if (state.failure != null) ErrorView(error: state.failure!),
                    if (state.analysis != null && state.canContinue)
                      _AiBanner(
                        text: state.analysis!.manualSelectionRequired
                            ? 'Fotoğrafın yüklendi. Konuyu kendin seçerek devam edebilirsin.'
                            : 'Önerin hazır. Konuyu kontrol edip onayla veya değiştir.',
                      ),
                    const SizedBox(height: 28),
                    const Spacer(),
                    if (!selected)
                      Row(
                        children: [
                          Expanded(
                            flex: 13,
                            child: FilledButton.icon(
                              style: _captureButton(true),
                              onPressed: state.busy
                                  ? null
                                  : () => vm.selectImage(ImageOrigin.camera),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Kamera'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 10,
                            child: OutlinedButton.icon(
                              style: _captureButton(false),
                              onPressed: state.busy
                                  ? null
                                  : () => vm.selectImage(ImageOrigin.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Galeri'),
                            ),
                          ),
                        ],
                      )
                    else
                      HatoraPrimaryButton(
                        solidColor: AppColors.accent,
                        label: state.canContinue
                            ? (state.analysis!.manualSelectionRequired
                                  ? 'Konuyu kendim seçeyim'
                                  : 'Öneriyi incele')
                            : state.failure != null
                            ? 'Yüklemeyi yeniden dene'
                            : 'Yükle ve analiz et',
                        busy: state.busy,
                        busyLabel: 'Analiz ediliyor…',
                        onPressed: state.busy
                            ? null
                            : state.canContinue
                            ? () => context.push(
                                Routes.confirm,
                                extra: state.seed,
                              )
                            : vm.analyze,
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

  ButtonStyle _captureButton(bool filled) => FilledButton.styleFrom(
    minimumSize: const Size(0, 62),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    backgroundColor: filled ? AppColors.accent : AppColors.surface,
    foregroundColor: filled ? AppColors.surface : AppColors.primaryInk,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(21),
      side: filled ? BorderSide.none : const BorderSide(color: AppColors.line),
    ),
  );

  Future<void> _change(
    BuildContext context,
    QuestionCaptureViewModel vm,
  ) async {
    final origin = await showModalBottomSheet<ImageOrigin>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(c, ImageOrigin.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(c, ImageOrigin.gallery),
            ),
          ],
        ),
      ),
    );
    if (origin != null) await vm.selectImage(origin);
  }
}

class CaptureSteps extends StatelessWidget {
  const CaptureSteps({super.key, required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0)
            SizedBox(
              width: 42,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  height: 2,
                  color: selected && i == 1
                      ? AppColors.success
                      : AppColors.line,
                ),
              ),
            ),
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected && i == 0
                  ? AppColors.success
                  : i == (selected ? 1 : 0)
                  ? AppColors.accent
                  : AppColors.surfaceMuted,
            ),
            child: selected && i == 0
                ? const Icon(Icons.check, size: 16, color: AppColors.surface)
                : Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: i == (selected ? 1 : 0)
                          ? AppColors.surface
                          : AppColors.secondaryText,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Text(
            ['Fotoğraf', 'Analiz', 'Kaydet'][i],
            style: TextStyle(
              fontSize: MediaQuery.textScalerOf(context).scale(14) > 17
                  ? 10
                  : 14,
              fontWeight: FontWeight.w600,
              color: selected && i == 0
                  ? AppColors.success
                  : i == (selected ? 1 : 0)
                  ? AppColors.accent
                  : AppColors.secondaryText,
            ),
          ),
        ],
      ],
    ),
  );
}

class CaptureTip extends StatelessWidget {
  const CaptureTip(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check, size: 17, color: AppColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );
}

class CapturePhotoPlaceholder extends StatelessWidget {
  const CapturePhotoPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.33,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: CustomPaint(painter: _CaptureCorners()),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    size: 27,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Soru buraya gelecek',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CaptureCorners extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final x in [0.0, size.width]) {
      for (final y in [0.0, size.height]) {
        final dx = x == 0 ? 1.0 : -1.0, dy = y == 0 ? 1.0 : -1.0;
        final p = Path()
          ..moveTo(x + dx * 26, y)
          ..lineTo(x + dx * 10, y)
          ..quadraticBezierTo(x, y, x, y + dy * 10)
          ..lineTo(x, y + dy * 26);
        canvas.drawPath(p, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const reasonLabels = {
  MistakeReason.carelessness: 'Dikkatsizlik',
  MistakeReason.conceptGap: 'Kavram eksikliği',
  MistakeReason.calculationError: 'İşlem hatası',
  MistakeReason.misread: 'Yanlış okuma',
  MistakeReason.forgotInformation: 'Bilgiyi unutma',
  MistakeReason.timePressure: 'Zaman baskısı',
  MistakeReason.other: 'Diğer',
};
const difficultyLabels = {
  Difficulty.hard: 'Zor',
  Difficulty.medium: 'Orta',
  Difficulty.easy: 'Kolay',
};

class QuestionConfirmScreen extends ConsumerWidget {
  const QuestionConfirmScreen({super.key, required this.seed});
  final ConfirmationSeed seed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = confirmViewModelProvider(seed);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    ref.listen(provider, (previous, next) {
      if (previous?.created == null && next.created != null) {
        ref.invalidate(progressViewModelProvider);
        ref.invalidate(dashboardViewModelProvider);
        ref.invalidate(myQuestionsViewModelProvider);
      }
    });
    final suggestion = vm.suggestedTopic;
    final saved = state.created;
    if (saved != null) {
      return QuestionSavedScreen(
        question: saved,
        image: seed.image,
        onAdd: () {
          ref.read(captureViewModelProvider.notifier).reset();
          context.go(Routes.capture);
        },
        onQuestions: () {
          ref.invalidate(myQuestionsViewModelProvider);
          context.go(Routes.myQuestions);
        },
        onHome: () => context.go(Routes.home),
      );
    }
    final catalog = state.catalog.asData?.value;
    final chosen = state.topic ?? suggestion;
    final complete = [
      state.topic != null,
      state.answer != null &&
          catalog != null &&
          List.generate(
            catalog.exam.answerOptionCount,
            (i) => String.fromCharCode(65 + i),
          ).contains(state.answer),
      state.mistakeReason != null,
      state.difficulty != null,
    ].where((v) => v).length;
    Future<void> chooseTopic() async {
      if (catalog == null || state.busy) return;
      final topic = await context.push<Topic>(
        Routes.topics,
        extra: catalog.topics,
      );
      if (context.mounted && topic != null) vm.selectTopic(topic);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            const Text('Kontrol et ve kaydet'),
            Text('Adım 2 / 2', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.all(5),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.line),
              ),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.capture);
              }
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Zorunlu alanlar',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    complete == 4
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    color: complete == 4
                        ? AppColors.success
                        : AppColors.secondaryText,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '$complete / 4 tamam',
                      style: TextStyle(
                        fontSize: 13,
                        color: complete == 4
                            ? AppColors.success
                            : AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
              HatoraPrimaryButton(
                solidColor: AppColors.accent,
                label: 'Kaydet ve deftere ekle',
                busy: state.busy,
                busyLabel: 'Kaydediliyor…',
                onPressed: catalog == null ? null : vm.submit,
              ),
            ],
          ),
        ),
      ),
      body: PageBody(
        children: [
          const LinearProgressIndicator(
            value: 1,
            minHeight: 4,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            color: AppColors.accent,
          ),
          const SizedBox(height: 20),
          ReferenceCard(
            padding: 12,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _photo(context),
              child: Row(
                children: [
                  SizedBox(
                    width: 115,
                    child: QuestionImageCard(
                      bytes: seed.image.bytes,
                      height: 90,
                      bottomMargin: 0,
                      backgroundColor: const Color(0xFFFAFAF7),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soru fotoğrafı',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Büyütmek için dokun',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(
                              Icons.fullscreen,
                              color: AppColors.accent,
                              size: 17,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Tam ekran',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _ConfirmHeading('Ders ve konu'),
          state.catalog.when(
            loading: () => const LoadingView(label: 'Konu listesi yükleniyor…'),
            error: (error, _) => ErrorView(error: error, onRetry: vm.load),
            data: (_) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: AppColors.accent, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_outlined,
                        color: AppColors.accent,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.topic != null && state.topic?.id != suggestion?.id
                            ? 'Seçtiğin konu'
                            : suggestion != null
                            ? 'AI önerisi'
                            : 'Ders ve konu seç',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (chosen != null) ...[
                    Text(
                      chosen.groupLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      chosen.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ] else
                    Text(
                      'Ders ve konuyu kendin seçebilirsin.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (suggestion != null) ...[
                        Expanded(
                          child: FilledButton.icon(
                            style: _confirmButton(true),
                            onPressed: state.busy
                                ? null
                                : () => vm.selectTopic(suggestion),
                            icon: Icon(
                              state.topic?.id == suggestion.id
                                  ? Icons.check
                                  : Icons.check_circle_outline,
                              size: 17,
                            ),
                            label: Text(
                              state.topic?.id == suggestion.id
                                  ? 'Onaylandı'
                                  : 'Onayla',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: FilledButton.icon(
                          style: _confirmButton(false),
                          onPressed: state.busy ? null : chooseTopic,
                          icon: const Icon(Icons.search, size: 17),
                          label: Text(
                            chosen == null ? 'Konu seç' : 'Başka konu',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.fieldErrors.contains('topicId'))
            const _RequiredHint('Bir konu seç.'),
          const _ConfirmHeading('Doğru cevap'),
          if (catalog != null)
            Row(
              children: [
                for (var i = 0; i < catalog.exam.answerOptionCount; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        padding: EdgeInsets.zero,
                        backgroundColor:
                            state.answer == String.fromCharCode(65 + i)
                            ? AppColors.success
                            : AppColors.surface,
                        foregroundColor:
                            state.answer == String.fromCharCode(65 + i)
                            ? AppColors.surface
                            : AppColors.primaryInk,
                        side: BorderSide(
                          color: state.answer == String.fromCharCode(65 + i)
                              ? AppColors.success
                              : AppColors.line,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: state.busy
                          ? null
                          : () => vm.setAnswer(String.fromCharCode(65 + i)),
                      child: Text(String.fromCharCode(65 + i)),
                    ),
                  ),
                ],
              ],
            ),
          if (state.fieldErrors.contains('correctAnswer'))
            const _RequiredHint('Doğru cevabı seç.'),
          const _ConfirmHeading('Neden yanlış yaptın?'),
          LayoutBuilder(
            builder: (context, c) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: reasonLabels.entries
                  .map(
                    (e) => SizedBox(
                      width:
                          e.key == MistakeReason.other ||
                              MediaQuery.textScalerOf(context).scale(14) > 18
                          ? c.maxWidth
                          : (c.maxWidth - 10) / 2,
                      child: QuestionReasonChoice(
                        label: e.value,
                        selected: state.mistakeReason == e.key,
                        onTap: state.busy ? null : () => vm.setReason(e.key),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (state.fieldErrors.contains('mistakeReason'))
            const _RequiredHint('Hata nedenini seç.'),
          const _ConfirmHeading('Zorluk'),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                for (final e in [
                  (Difficulty.easy, 'Kolay', AppColors.success),
                  (Difficulty.medium, 'Orta', AppColors.warning),
                  (Difficulty.hard, 'Zor', AppColors.error),
                ])
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 12,
                        ),
                        backgroundColor: state.difficulty == e.$1
                            ? AppColors.surface
                            : Colors.transparent,
                        foregroundColor: state.difficulty == e.$1
                            ? AppColors.primaryInk
                            : AppColors.secondaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: state.busy
                          ? null
                          : () => vm.setDifficulty(e.$1),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: e.$3,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(e.$2),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (state.fieldErrors.contains('difficulty'))
            const _RequiredHint('Zorluk seçimi gerekli.'),
          const _ConfirmHeading('Ek bilgiler', optional: true),
          TextFormField(
            initialValue: state.shortNote,
            enabled: !state.busy,
            onChanged: vm.setNote,
            maxLength: 2000,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Bir dahaki sefere neyi hatırlamak istersin?',
              prefixIcon: Icon(Icons.edit_note_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: state.source,
            enabled: !state.busy,
            onChanged: vm.setSource,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Kitap veya deneme adı',
              prefixIcon: Icon(Icons.menu_book_outlined),
              counterText: '',
            ),
          ),
          if (state.failure != null) ErrorView(error: state.failure!),
          if (state.failure?.code == 'ANALYSIS_EXPIRED')
            TextButton(
              onPressed: () {
                ref.read(captureViewModelProvider.notifier).reset();
                context.go(Routes.capture);
              },
              child: const Text('Fotoğrafı yeniden yükle'),
            ),
        ],
      ),
    );
  }

  ButtonStyle _confirmButton(bool primary) => FilledButton.styleFrom(
    minimumSize: const Size(0, 42),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    backgroundColor: primary ? AppColors.accent : AppColors.surfaceMuted,
    foregroundColor: primary ? AppColors.surface : AppColors.accent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
  Future<void> _photo(BuildContext context) => showDialog<void>(
    context: context,
    builder: (c) => Dialog.fullscreen(
      backgroundColor: AppColors.primaryInk,
      child: Scaffold(
        backgroundColor: AppColors.primaryInk,
        appBar: AppBar(
          backgroundColor: AppColors.primaryInk,
          foregroundColor: AppColors.surface,
          title: const Text('Soru fotoğrafı'),
          leading: IconButton(
            onPressed: () => Navigator.pop(c),
            icon: const Icon(Icons.close),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: .5,
            maxScale: 5,
            child: Image.memory(
              seed.image.bytes,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Text(
                'Görsel önizlenemiyor',
                style: TextStyle(color: AppColors.surface),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ConfirmHeading extends StatelessWidget {
  const _ConfirmHeading(this.title, {this.optional = false});
  final String title;
  final bool optional;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (optional)
          Text('İsteğe bağlı', style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class QuestionReasonChoice extends StatelessWidget {
  const QuestionReasonChoice({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      backgroundColor: selected ? AppColors.accentSoft : AppColors.surface,
      foregroundColor: selected ? AppColors.accent : AppColors.primaryInk,
      side: BorderSide(
        color: selected ? AppColors.accent : AppColors.line,
        width: selected ? 1.2 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    onPressed: onTap,
    child: Row(
      mainAxisAlignment: label == 'Diğer'
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Icon(
          selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 17,
          color: selected ? AppColors.accent : AppColors.secondaryText,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 13,
              color: selected ? AppColors.accent : AppColors.primaryInk,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AiBanner extends StatelessWidget {
  const _AiBanner({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.base),
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.accentSoft,
      borderRadius: AppRadius.lgAll,
      border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.auto_awesome_outlined,
          color: AppColors.accent,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI önerisi',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: 2),
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RequiredHint extends StatelessWidget {
  const _RequiredHint(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 14, color: AppColors.error),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppColors.error),
        ),
      ],
    ),
  );
}
