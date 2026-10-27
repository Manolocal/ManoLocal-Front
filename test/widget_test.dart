import 'package:flutter_test/flutter_test.dart';
import 'package:manolocal_front/core/di/injection_container.dart';
import 'package:manolocal_front/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App renders Dashboard successfully smoke test', (WidgetTester tester) async {
    // Mock initial SharedPreferences
    SharedPreferences.setMockInitialValues({});

    final container = await DependencyContainer.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: container.providers,
        child: const ManoLocalApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Comprobar que carga el Dashboard y sus elementos principales
    expect(find.text('Dashboard ManoLocal'), findsOneWidget);
    expect(find.text('Modo Desarrollo / Invitado'), findsOneWidget);
  });
}
