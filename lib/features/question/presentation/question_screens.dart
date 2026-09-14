import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../catalog/domain/catalog.dart';
import '../domain/question.dart';
import 'question_capture_view_model.dart';

class QuestionCaptureScreen extends ConsumerWidget {
  const QuestionCaptureScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(captureViewModelProvider);
    final vm = ref.read(captureViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Yanlış ekle')),
      body: PageBody(
        children: [
          Text(
            'Her hata, yeni bir\nöğrenme fırsatı.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text('Soruyu net ve tamamı görünecek şekilde fotoğrafla.'),
          const SizedBox(height: 24),
          if (state.image != null)
            QuestionImageCard(bytes: state.image!.bytes)
          else
            const EmptyView(
              title: 'Soruyu fotoğrafla',
              message: 'Kamerayı aç veya galerinden bir soru seç.',
              icon: Icons.add_a_photo_outlined,
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.busy
                      ? null
                      : () => vm.selectImage(ImageOrigin.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.busy
                      ? null
                      : () => vm.selectImage(ImageOrigin.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                ),
              ),
            ],
          ),
          if (state.phase == CapturePhase.analyzing)
            const LoadingView(label: 'Ders ve konu önerisi hazırlanıyor…'),
          if (state.failure != null) ErrorView(error: state.failure!),
          if (state.analysis != null && state.canContinue)
            _AiBanner(
              text: state.analysis!.manualSelectionRequired
                  ? 'Fotoğrafın yüklendi. Konuyu kendin seçerek devam edebilirsin.'
                  : 'Önerin hazır. Konuyu kontrol edip onayla veya değiştir.',
            ),
          if (!state.canContinue)
            HatoraPrimaryButton(
              label: state.failure != null
                  ? 'Yüklemeyi yeniden dene'
                  : 'Fotoğrafı yükle ve analiz et',
              busy: state.busy,
              onPressed: state.image == null ? null : vm.analyze,
            ),
          if (state.canContinue)
            HatoraPrimaryButton(
              label: state.analysis!.manualSelectionRequired
                  ? 'Konuyu kendim seçeyim'
                  : 'Öneriyi incele',
              onPressed: () => context.push(Routes.confirm, extra: state.seed),
            ),
        ],
      ),
    );
  }
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
      return Scaffold(
        appBar: AppBar(title: const Text('Soru kaydedildi')),
        body: PageBody(
          children: [
            EmptyView(
              icon: Icons.check_circle_outline,
              title: 'Defterine eklendi',
              message: '${saved.subjectName} · ${saved.topicName}',
            ),
            if (saved.nextReviewDate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'İlk tekrar tarihi: ${_date(saved.nextReviewDate!)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.base),
            HatoraPrimaryButton(
              label: 'Yeni soru ekle',
              onPressed: () {
                ref.read(captureViewModelProvider.notifier).reset();
                context.go(Routes.capture);
              },
            ),
            TextButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Ana sayfaya dön'),
            ),
            TextButton(
              onPressed: () {
                ref.invalidate(myQuestionsViewModelProvider);
                context.go(Routes.myQuestions);
              },
              child: const Text('Sorularımı gör'),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Kontrol et ve kaydet')),
      body: PageBody(
        children: [
          QuestionImageCard(bytes: seed.image.bytes),
          _AiBanner(
            text: seed.analysis.manualSelectionRequired
                ? 'Konu seçimini sen tamamla. AI önerileri yalnızca yardımcıdır.'
                : 'Son karar senin. Öneriyi onaylayabilir veya değiştirebilirsin.',
            action: suggestion == null
                ? null
                : TextButton(
                    onPressed: state.busy
                        ? null
                        : () => vm.selectTopic(suggestion),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(
                      'Öneriyi seç: ${suggestion.groupLabel} · ${suggestion.name}',
                    ),
                  ),
          ),
          state.catalog.when(
            loading: () => const LoadingView(label: 'Konu listesi yükleniyor…'),
            error: (error, _) => ErrorView(error: error, onRetry: vm.load),
            data: (catalog) => AbsorbPointer(
              absorbing: state.busy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader('Ders ve konu *'),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final topic = await context.push<Topic>(
                        Routes.topics,
                        extra: catalog.topics,
                      );
                      if (context.mounted && topic != null) {
                        vm.selectTopic(topic);
                      }
                    },
                    icon: const Icon(Icons.search),
                    label: Text(
                      state.topic == null
                          ? 'Konu seç'
                          : '${state.topic!.groupLabel}\n${state.topic!.name}',
                    ),
                  ),
                  if (state.fieldErrors.contains('topicId'))
                    const _RequiredHint('Bir konu seç.'),
                  const SectionHeader('Doğru cevap *'),
                  AnswerOptions(
                    count: catalog.exam.answerOptionCount,
                    selected: state.answer,
                    onSelected: vm.setAnswer,
                  ),
                  if (state.fieldErrors.contains('correctAnswer'))
                    const _RequiredHint('Doğru cevabı seç.'),
                  const SectionHeader('Neden yanlış yaptın? *'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reasonLabels.entries
                        .map(
                          (e) => ChoiceChip(
                            label: Text(e.value),
                            selected: state.mistakeReason == e.key,
                            onSelected: (_) => vm.setReason(e.key),
                          ),
                        )
                        .toList(),
                  ),
                  if (state.fieldErrors.contains('mistakeReason'))
                    const _RequiredHint('Hata nedenini seç.'),
                  const SectionHeader('Zorluk *'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: difficultyLabels.entries
                        .map(
                          (e) => ChoiceChip(
                            label: Text(e.value),
                            selected: state.difficulty == e.key,
                            onSelected: (_) => vm.setDifficulty(e.key),
                          ),
                        )
                        .toList(),
                  ),
                  if (state.fieldErrors.contains('difficulty'))
                    const _RequiredHint('Zorluk seçimi gerekli.'),
                  const SectionHeader('Kısa not'),
                  TextFormField(
                    initialValue: state.shortNote,
                    onChanged: vm.setNote,
                    maxLength: 2000,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Bir dahaki sefere neyi hatırlamak istersin?',
                    ),
                  ),
                  const SectionHeader('Kaynak'),
                  TextFormField(
                    initialValue: state.source,
                    onChanged: vm.setSource,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Kitap veya deneme adı (isteğe bağlı)',
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
                  HatoraPrimaryButton(
                    label: 'Onayla ve kaydet',
                    busy: state.busy,
                    onPressed: vm.submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBanner extends StatelessWidget {
  const _AiBanner({required this.text, this.action});
  final String text;
  final Widget? action;
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
              ?action,
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

String _date(DateTime date) => '${date.day}.${date.month}.${date.year}';
