import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

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
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: true,
  builder: (context) =>
      AppBottomSheetContent(title: title, child: builder(context)),
);

class AppBottomSheetContent extends StatelessWidget {
  const AppBottomSheetContent({
    super.key,
    required this.title,
    required this.child,
  });
  final String title;
  final Widget child;

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
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
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
