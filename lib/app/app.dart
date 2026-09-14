import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class HatoraApp extends ConsumerWidget {
  const HatoraApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Hatora',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    routerConfig: ref.watch(routerProvider),
  );
}
