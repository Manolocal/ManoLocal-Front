import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/navigation_keys.dart';

/// Widget raíz de ManoLocal configurado con tema oficial, GoRouter y claves globales.
class ManoLocalApp extends StatelessWidget {
  final GoRouter router;

  const ManoLocalApp({
    super.key,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp.router(
      title: 'ManoLocal',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
    );
  }
}
