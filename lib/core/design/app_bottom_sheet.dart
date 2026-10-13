import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// TR: Tüm modal sheet'lerin (ör. PDF Dışa Aktar) paylaştığı tutamaç +
/// başlık + kapatma iskeleti. Sayfa geçişi yerine tek, tutarlı bir sheet
/// deneyimi sağlar.
/// EN: The handle + title + close skeleton every modal sheet (e.g. PDF
/// Export) shares, so a sheet feels like one consistent pattern instead of
/// a full page push.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  String? subtitle,
  IconData? icon,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: true,
  builder: (context) => AppBottomSheetContent(
    title: title,
    subtitle: subtitle,
    icon: icon,
    child: builder(context),
  ),
);

class AppBottomSheetContent extends StatelessWidget {
  const AppBottomSheetContent({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
  });
  final String title;
  final Widget child;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.base,
            AppSpacing.base,
            0,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceMuted,
                  shape: const CircleBorder(),
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
                tooltip: 'Kapat',
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: child,
          ),
        ),
      ],
    ),
  );
}
