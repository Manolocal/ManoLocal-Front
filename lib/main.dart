import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/utils/navigation_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de la inyección de dependencias (SharedPreferences, Dio, Repositorios)
  final container = await DependencyContainer.init();

  runApp(
    MultiProvider(
      providers: container.providers,
      child: const ManoLocalApp(),
    ),
  );
}

class ManoLocalApp extends StatelessWidget {
  const ManoLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ManoLocal',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Azul moderno
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
