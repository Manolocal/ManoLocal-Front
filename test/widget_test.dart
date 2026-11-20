import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manolocal_front/src/app.dart';
import 'package:manolocal_front/src/core/di/injection_container.dart';
import 'package:manolocal_front/src/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await resetDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  testWidgets(
    'Inicializa DI, aplica paleta oficial y navega entre Login, Dashboard y Perfil',
    (WidgetTester tester) async {
      await initDependencies();

      await tester.pumpWidget(
        MultiProvider(
          providers: buildAppProviders(),
          child: ManoLocalApp(router: sl<GoRouter>()),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica paleta oficial (#2B2D31, #D9DADC, #FFC93C) en el Theme
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final colorScheme = materialApp.theme!.colorScheme;
      expect(colorScheme.primary, AppColors.yellow);
      expect(colorScheme.secondary, AppColors.gray);
      expect(colorScheme.outline, AppColors.silver);

      // Inicia en la ruta base /login
      expect(find.text('ManoLocal · Acceso'), findsOneWidget);

      // Navega hacia /dashboard
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard ManoLocal'), findsOneWidget);
      expect(
        find.text('Módulos Integrados desde ManoLocal-Back'),
        findsOneWidget,
      );

      // Navega hacia /profile
      await tester.tap(find.byTooltip('Ir a Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Perfil de Usuario'), findsOneWidget);
      expect(find.text('Token JWT en Almacenamiento Local'), findsOneWidget);
    },
  );
}
