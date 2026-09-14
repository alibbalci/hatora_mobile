import 'package:flutter/material.dart';

/// TR: Birincil olmayan ama yine de net bir eylem için — mevcut
/// `OutlinedButtonThemeData`'yı kullanır, kendi stilini icat etmez.
/// EN: For a non-primary but still clear action — rides the shared
/// `OutlinedButtonThemeData` instead of inventing its own look.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: icon == null
        ? OutlinedButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          ),
  );
}
