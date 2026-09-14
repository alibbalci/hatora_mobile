import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../error/app_failure.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.base,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          children: children,
        ),
      ),
    ),
  );
}

class HatoraPrimaryButton extends StatelessWidget {
  const HatoraPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.busyLabel,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? busyLabel;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        gradient: onPressed == null
            ? null
            : const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.accent, AppColors.accentEnd],
              ),
        color: onPressed == null ? AppColors.line : null,
      ),
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.secondaryText,
        ),
        child: busy
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  ),
                  if (busyLabel != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Text(busyLabel!),
                  ],
                ],
              )
            : Text(label, textAlign: TextAlign.center),
      ),
    ),
  );
}

class SelectableOptionCard extends StatelessWidget {
  const SelectableOptionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.accentSoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(
            color: selected ? AppColors.accent : AppColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.accent : AppColors.secondaryText,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.labelMedium,
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
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?trailing,
      ],
    ),
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Yükleniyor…'});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xxl),
    child: Column(
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error is AppFailure
                      ? (error as AppFailure).message
                      : 'Bir sorun oluştu.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (onRetry != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        alignment: Alignment.centerLeft,
                      ),
                      child: const Text('Tekrar dene'),
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

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.auto_stories_outlined,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 26, color: AppColors.accent),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class QuestionImageCard extends StatelessWidget {
  const QuestionImageCard({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    decoration: BoxDecoration(
      borderRadius: AppRadius.lgAll,
      border: Border.all(color: AppColors.line),
      color: AppColors.surfaceMuted,
    ),
    child: Image.memory(
      bytes,
      height: 240,
      width: double.infinity,
      fit: BoxFit.contain,
      semanticLabel: 'Seçilen soru fotoğrafı',
      errorBuilder: (_, _, _) => const SizedBox(
        height: 160,
        child: Center(child: Text('Görsel önizlenemiyor')),
      ),
    ),
  );
}

enum AnswerOptionState { neutral, correct, wrong }

class AnswerOptions extends StatelessWidget {
  const AnswerOptions({
    super.key,
    required this.count,
    required this.selected,
    required this.onSelected,
    this.correctAnswer,
    this.revealed = false,
  });
  final int count;
  final String? selected;
  final ValueChanged<String> onSelected;
  final String? correctAnswer;
  final bool revealed;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: List.generate(count, (i) {
      final label = String.fromCharCode(65 + i);
      final isSelected = label == selected;
      final state = !revealed
          ? AnswerOptionState.neutral
          : label == correctAnswer
          ? AnswerOptionState.correct
          : (isSelected ? AnswerOptionState.wrong : AnswerOptionState.neutral);
      final (bg, border, fg, trailingIcon) = switch (state) {
        AnswerOptionState.correct => (
          AppColors.successSoft,
          AppColors.success,
          AppColors.success,
          Icons.check_rounded,
        ),
        AnswerOptionState.wrong => (
          AppColors.errorSoft,
          AppColors.error,
          AppColors.error,
          Icons.close_rounded,
        ),
        AnswerOptionState.neutral => (
          isSelected && !revealed ? AppColors.accentSoft : AppColors.surface,
          isSelected && !revealed ? AppColors.accent : AppColors.line,
          isSelected && !revealed ? AppColors.accent : AppColors.primaryInk,
          null,
        ),
      };
      final dimmed = revealed && state == AnswerOptionState.neutral;
      return Semantics(
        selected: isSelected,
        label: '$label şıkkı',
        button: true,
        child: SizedBox(
          width: 56,
          height: 56,
          child: OutlinedButton(
            onPressed: revealed ? null : () => onSelected(label),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(56, 56),
              backgroundColor: bg,
              foregroundColor: fg,
              disabledForegroundColor: dimmed ? AppColors.secondaryText : fg,
              disabledBackgroundColor: bg,
              side: BorderSide(color: border, width: isSelected ? 1.8 : 1),
              shape: const CircleBorder(),
            ),
            child: trailingIcon == null
                ? Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  )
                : Icon(trailingIcon, size: 22),
          ),
        ),
      );
    }),
  );
}
