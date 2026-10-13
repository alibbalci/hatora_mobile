import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ReferenceHeader extends StatelessWidget {
  const ReferenceHeader({
    super.key,
    required this.title,
    this.caption,
    this.action,
  });
  final String title;
  final String? caption;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (caption != null)
                Text(caption!, style: Theme.of(context).textTheme.bodySmall),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontSize: 28, letterSpacing: -.7),
              ),
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class ReferenceCard extends StatelessWidget {
  const ReferenceCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = 20,
  });
  final Widget child;
  final Color color;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(26),
      border: color == AppColors.surface
          ? Border.all(color: AppColors.line)
          : null,
    ),
    child: child,
  );
}

class ReferenceSegments<T> extends StatelessWidget {
  const ReferenceSegments({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
  });
  final Map<T, String> values;
  final T selected;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: values.entries
          .map(
            (e) => Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: e.key == selected
                      ? AppColors.surface
                      : Colors.transparent,
                  foregroundColor: e.key == selected
                      ? AppColors.primaryInk
                      : AppColors.secondaryText,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => onChanged(e.key),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

Color subjectColor(String name) {
  final n = name.toLowerCase();
  if (n.contains('türkçe') || n.contains('turkce')) return AppColors.success;
  if (n.contains('tarih')) return AppColors.warning;
  if (n.contains('coğraf') || n.contains('güncel')) {
    return AppColors.subjectRose;
  }
  return AppColors.accent;
}

class ReferenceTag extends StatelessWidget {
  const ReferenceTag({
    super.key,
    required this.label,
    this.color = AppColors.accent,
    this.icon,
    this.backgroundColor,
  });
  final String label;
  final Color color;
  final IconData? icon;
  final Color? backgroundColor;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: backgroundColor ?? color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

String referenceDate(DateTime date) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Owns its input until the closing route animation has finished.
class ReferenceInputDialog extends StatefulWidget {
  const ReferenceInputDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.numeric = false,
  });
  final String title, initialValue;
  final bool numeric;
  @override
  State<ReferenceInputDialog> createState() => _ReferenceInputDialogState();
}

class _ReferenceInputDialogState extends State<ReferenceInputDialog> {
  late final controller = TextEditingController(text: widget.initialValue);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: controller,
      autofocus: !widget.numeric,
      maxLength: widget.numeric ? null : 100,
      keyboardType: widget.numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        helperText: widget.numeric ? '1–200 soru' : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Vazgeç'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text),
        child: const Text('Kaydet'),
      ),
    ],
  );
}
