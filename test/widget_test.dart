import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manolocal_front/src/app.dart';
import 'package:manolocal_front/src/core/constants/storage_keys.dart';
import 'package:manolocal_front/src/core/di/injection_container.dart';
import 'package:manolocal_front/src/core/theme/app_colors.dart';
import 'package:manolocal_front/src/core/utils/formatters.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adaptador HTTP simulado para pruebas de flujo completo sin depender de un servidor vivo.
class _FakeBackendAdapter implements HttpClientAdapter {
  final String role;

  _FakeBackendAdapter({this.role = 'ESPECIALISTA'});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    dynamic body = {'data': {}};

    if (path == '/users/me') {
      body = {
        'data': {
          'id': 'user-1',
          'email': 'carlos@manolocal.com',
          'name': 'Carlos López',
          'role': role,
          'status': 'ACTIVO',
          'profile': {
            'id': 'prof-1',
            'userId': 'user-1',
            'fullName': 'Carlos López',
            'phone': '5512345678',
            'address': 'Av. Reforma 100',
            'postalCode': '01000',
            'ineUrl': 'https://example.com/ine.jpg',
            'selfieUrl': 'https://example.com/selfie.jpg',
          },
          'knowledges': role == 'ESPECIALISTA'
              ? [
                  {
                    'id': 'k-1',
                    'name': 'Plomería residencial',
                    'verifications': [],
                  },
                ]
              : [],
        },
      };
    } else if (path == '/jobs/me') {
      body = {
        'data': {
          'data': [],
          'meta': {'total': 0, 'page': 1, 'limit': 15, 'totalPages': 0},
        },
      };
    } else if (path == '/chat/rooms') {
      body = {'data': []};
    } else if (path == '/wallet/balance') {
      body = {
        'data': {
          'id': 'w-1',
          'userId': 'user-1',
          'balanceDisponible': 250.0,
          'balanceCongelado': 50.0,
          'balanceTotal': 300.0,
        },
      };
    } else if (path == '/wallet/transactions') {
      body = {
        'data': {
          'data': [
            {
              'id': 'tx-1',
              'walletId': 'w-1',
              'monto': 250.0,
              'tipo': 'RECARGA',
              'descripcion': 'Recarga inicial',
              'fecha': '2026-11-19T10:00:00.000Z',
            },
          ],
          'meta': {'total': 1, 'page': 1, 'limit': 15, 'totalPages': 1},
        },
      };
    } else if (path == '/catalog/me') {
      body = {
        'data': {
          'images': [],
          'quota': {'active': 0, 'limit': 10, 'remaining': 10},
        },
      };
    } else if (path.startsWith('/search/geo-info/')) {
      body = {
        'data': {
          'municipio': 'Dolores Hidalgo Cuna de la Independencia Nacional',
          'postalCodes': ['37800', '37806'],
        },
      };
    } else if (path == '/chat/rooms/room-1/messages') {
      body = {
        'data': {
          'data': [
            {
              'id': 'm-1',
              'roomId': 'room-1',
              'senderId': 'spec-1',
              'content': 'Hola, te envío la propuesta del trabajo.',
              'isRead': true,
              'createdAt': '2026-11-20T14:00:00.000Z',
              'sender': {
                'id': 'spec-1',
                'name': 'Juan Perez',
                'email': 'juan@manolocal.com',
                'role': 'ESPECIALISTA',
                'profile': {'fullName': 'Juan Perez Leon'},
              },
            },
            {
              'id': 'm-2',
              'roomId': 'room-1',
              'senderId': 'user-1',
              'content': 'Perfecto, la reviso ahora mismo.',
              'isRead': false,
              'createdAt': '2026-11-20T14:01:00.000Z',
              'sender': {
                'id': 'user-1',
                'name': 'Carlos López',
                'email': 'carlos@manolocal.com',
                'role': 'EMPLEADOR',
                'profile': {'fullName': 'Carlos López'},
              },
            },
          ],
          'meta': {'total': 2, 'page': 1, 'limit': 50, 'totalPages': 1},
        },
      };
    } else if (path == '/jobs/room/room-1') {
      body = {
        'data': {
          'roomId': 'room-1',
          'activeJob': {
            'id': 'job-1',
            'roomId': 'room-1',
            'title': 'Reparación de tubería',
            'agreedPrice': 650.0,
            'feeAmount': 50.0,
            'status': 'PENDING',
            'room': {
              'id': 'room-1',
              'employerId': 'user-1',
              'specialistId': 'spec-1',
            },
          },
          'jobs': [],
        },
      };
    } else if (path == '/chat/rooms/room-1/read') {
      body = {'data': {'roomId': 'room-1', 'markedCount': 1}};
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await resetDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  testWidgets(
    'Inicializa DI, conserva paleta oficial y permite flujo Login -> Registro',
    (WidgetTester tester) async {
      await initDependencies(
        httpClientAdapter: _FakeBackendAdapter(),
        enableSocket: false,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: buildAppProviders(),
          child: ManoLocalApp(router: sl<GoRouter>()),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica paleta oficial (#2B2D31, #D9DADC, #FFC93C)
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final colorScheme = materialApp.theme!.colorScheme;
      expect(colorScheme.primary, AppColors.yellow);
      expect(colorScheme.secondary, AppColors.gray);
      expect(colorScheme.outline, AppColors.silver);

      // Inicia en Login profesional
      expect(find.text('Bienvenido de vuelta'), findsOneWidget);
      expect(find.text('Continuar con verificación 2FA'), findsOneWidget);

      // Navega a Registro con selector de rol
      await tester.ensureVisible(find.text('Crear cuenta'));
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Crear cuenta en ManoLocal'), findsOneWidget);
      expect(find.text('Empleador'), findsOneWidget);
      expect(find.text('Especialista'), findsOneWidget);
    },
  );

  testWidgets(
    'Sesión autenticada como Especialista abre Dashboard y navega entre Billetera, Catálogo y Perfil',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.accessToken: 'jwt.test.token',
        StorageKeys.cachedUser: jsonEncode({
          'id': 'user-1',
          'email': 'carlos@manolocal.com',
          'name': 'Carlos López',
          'role': 'ESPECIALISTA',
          'status': 'ACTIVO',
        }),
      });

      await initDependencies(
        httpClientAdapter: _FakeBackendAdapter(),
        enableSocket: false,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: buildAppProviders(),
          child: ManoLocalApp(router: sl<GoRouter>()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hola, Carlos López'), findsOneWidget);

      // Navega a Billetera
      await tester.tap(find.text('Billetera'));
      await tester.pumpAndSettle();
      expect(find.text('Billetera Virtual'), findsOneWidget);
      expect(find.text('Recargar Saldo'), findsOneWidget);

      // Navega a Catálogo
      await tester.tap(find.text('Catálogo'));
      await tester.pumpAndSettle();
      expect(find.text('Mi Catálogo de Trabajos'), findsOneWidget);
      expect(find.text('0 / 10 fotos'), findsOneWidget);

      // Navega a Perfil
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('Plomería residencial'), findsOneWidget);
    },
  );

  testWidgets(
    'Sesión autenticada como Empleador abre Dashboard y navega entre Buscar, Mensajes y Trabajos',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.accessToken: 'jwt.emp.token',
        StorageKeys.cachedUser: jsonEncode({
          'id': 'user-1',
          'email': 'carlos@manolocal.com',
          'name': 'Carlos López',
          'role': 'EMPLEADOR',
          'status': 'ACTIVO',
        }),
      });

      await initDependencies(
        httpClientAdapter: _FakeBackendAdapter(role: 'EMPLEADOR'),
        enableSocket: false,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: buildAppProviders(),
          child: ManoLocalApp(router: sl<GoRouter>()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¿Qué oficio necesitas hoy?'), findsOneWidget);

      await tester.tap(find.text('Buscar').last);
      await tester.pumpAndSettle();
      expect(find.text('Buscar Especialistas'), findsOneWidget);

      await tester.tap(find.text('Trabajos'));
      await tester.pumpAndSettle();
      expect(find.text('Acuerdos de Trabajo'), findsOneWidget);
    },
  );

  testWidgets(
    'Pantallas principales se adaptan sin overflow en teléfono compacto (360x780 y 412x915)',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final viewport in const [Size(360, 780), Size(412, 915)]) {
        tester.view.physicalSize = viewport;
        SharedPreferences.setMockInitialValues({
          StorageKeys.accessToken: 'jwt.mobile.token',
          StorageKeys.cachedUser: jsonEncode({
            'id': 'user-1',
            'email': 'carlos@manolocal.com',
            'name': 'Carlos López',
            'role': 'EMPLEADOR',
            'status': 'INACTIVO',
          }),
        });

        await resetDependencies();
        await initDependencies(
          httpClientAdapter: _FakeBackendAdapter(role: 'EMPLEADOR'),
          enableSocket: false,
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: buildAppProviders(),
            child: ManoLocalApp(router: sl<GoRouter>()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Plomería'), findsOneWidget);

        // Navegar por todas las pestañas de Empleador en pantalla móvil
        await tester.tap(find.text('Buscar').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mensajes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Trabajos'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Perfil'));
        await tester.pumpAndSettle();

        // Validar modal de edición de perfil con municipio SEPOMEX largo
        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();
        final cpField = find.widgetWithText(
          TextFormField,
          'Código Postal (5 dígitos) *',
        );
        await tester.enterText(cpField, '37806');
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Dolores Hidalgo Cuna de la Independencia'),
          findsOneWidget,
        );
        Navigator.of(tester.element(cpField)).pop();
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'ChatRoomScreen alinea mensajes recibidos a la izquierda y enviados a la derecha con nombre, y permite al Empleador aceptar o rechazar',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.accessToken: 'jwt.emp.token',
        StorageKeys.cachedUser: jsonEncode({
          'id': 'user-1',
          'email': 'carlos@manolocal.com',
          'name': 'Carlos López',
          'role': 'EMPLEADOR',
          'status': 'ACTIVO',
        }),
      });

      await initDependencies(
        httpClientAdapter: _FakeBackendAdapter(role: 'EMPLEADOR'),
        enableSocket: false,
      );

      sl<GoRouter>().go('/chat/room-1');

      await tester.pumpWidget(
        MultiProvider(
          providers: buildAppProviders(),
          child: ManoLocalApp(router: sl<GoRouter>()),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica nombres de remitente
      expect(find.text('Juan Perez Leon'), findsOneWidget);
      expect(find.text('Tú · Carlos López'), findsOneWidget);

      // Verifica alineación izquierda (recibido) vs derecha (enviado)
      final receivedCenter = tester.getCenter(
        find.text('Hola, te envío la propuesta del trabajo.'),
      );
      final sentCenter = tester.getCenter(
        find.text('Perfecto, la reviso ahora mismo.'),
      );
      expect(receivedCenter.dx, lessThan(sentCenter.dx));

      // Verifica flujo de Empleador sobre propuesta PENDING: Aceptar o Rechazar
      // y que el cliente NUNCA vea información de la comisión de la app
      expect(find.text('Aceptar Acuerdo'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
      expect(find.textContaining('Comisión'), findsNothing);
      expect(find.textContaining(r'$50.00'), findsNothing);
      expect(find.textContaining('50 MXN'), findsNothing);
    },
  );

  group('Validadores y formateadores alineados con ManoLocal-Back', () {
    test('AppValidators valida contraseña fuerte, teléfono MX y CP MX', () {
      expect(AppValidators.strongPassword('Password123!'), isNull);
      expect(AppValidators.strongPassword('weak'), isNotNull);

      expect(AppValidators.phoneMx('5512345678', required: true), isNull);
      expect(AppValidators.phoneMx('1234', required: true), isNotNull);

      expect(AppValidators.postalCodeMx('01000', required: true), isNull);
      expect(AppValidators.postalCodeMx('123', required: true), isNotNull);
    });

    test('AppFormatters formatea montos MXN e iniciales', () {
      expect(AppFormatters.currency(50), contains('50.00'));
      expect(AppFormatters.currency(50), endsWith('MXN'));
      expect(AppFormatters.initials('Carlos López'), 'CL');
    });
  });
}
