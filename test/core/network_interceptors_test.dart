import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manolocal_front/src/core/network/api_client.dart';
import 'package:manolocal_front/src/core/network/dio_interceptor.dart';
import 'package:manolocal_front/src/core/network/error_handler.dart';
import 'package:manolocal_front/src/core/network/network_exceptions.dart';
import 'package:manolocal_front/src/core/services/token_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockHttpAdapter implements HttpClientAdapter {
  final int statusCode;
  final Map<String, dynamic> data;

  _MockHttpAdapter({required this.statusCode, required this.data});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorageService tokenStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPreferencesTokenStorage(prefs);
  });

  group('DioAuthInterceptor', () {
    test('inyecta cabecera Authorization Bearer cuando existe token JWT', () async {
      await tokenStorage.saveToken('jwt_super_secret_token_123');

      final interceptor = DioAuthInterceptor(tokenStorage: tokenStorage);
      final options = RequestOptions(path: '/users/me');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(
        options.headers['Authorization'],
        'Bearer jwt_super_secret_token_123',
      );
      expect(options.headers['Content-Type'], 'application/json');
      expect(options.headers['Accept'], 'application/json');
    });

    test('no inyecta Authorization si requiresAuth es false', () async {
      await tokenStorage.saveToken('jwt_super_secret_token_123');

      final interceptor = DioAuthInterceptor(tokenStorage: tokenStorage);
      final options = RequestOptions(
        path: '/auth/login',
        extra: const {'requiresAuth': false},
      );
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], isNull);
    });

    test('no fuerza Content-Type application/json cuando el cuerpo es FormData', () async {
      await tokenStorage.saveToken('jwt_multipart_token');

      final interceptor = DioAuthInterceptor(tokenStorage: tokenStorage);
      final formData = FormData.fromMap({'knowledgeId': 'know-123'});
      final options = RequestOptions(
        path: '/ai/verify-document',
        data: formData,
      );
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer jwt_multipart_token');
      expect(options.headers['Content-Type'], isNull);
    });
  });

  group('ErrorHandlerInterceptor', () {
    test('401 en ruta protegida limpia token y llama onSessionExpired', () async {
      await tokenStorage.saveToken('token_para_borrar');
      var sessionExpiredTriggered = false;

      final dio = Dio();
      dio.httpClientAdapter = _MockHttpAdapter(
        statusCode: 401,
        data: {
          'statusCode': 401,
          'message': 'Token inválido o expirado',
          'error': 'Unauthorized',
        },
      );

      dio.interceptors.add(
        ErrorHandlerInterceptor(
          tokenStorage: tokenStorage,
          onSessionExpired: () => sessionExpiredTriggered = true,
        ),
      );

      await expectLater(
        dio.get('/users/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<UnauthorizedException>().having(
              (err) => err.message,
              'message',
              'Token inválido o expirado',
            ),
          ),
        ),
      );

      expect(sessionExpiredTriggered, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await tokenStorage.getToken(), isNull);
    });

    test('401 en ruta pública (requiresAuth: false) conserva token y no expira sesión', () async {
      await tokenStorage.saveToken('token_existente');
      var sessionExpiredTriggered = false;

      final dio = Dio();
      dio.httpClientAdapter = _MockHttpAdapter(
        statusCode: 401,
        data: {
          'statusCode': 401,
          'message': 'Credenciales inválidas',
          'error': 'Unauthorized',
        },
      );

      dio.interceptors.add(
        ErrorHandlerInterceptor(
          tokenStorage: tokenStorage,
          onSessionExpired: () => sessionExpiredTriggered = true,
        ),
      );

      await expectLater(
        dio.post(
          '/auth/login',
          options: Options(extra: const {'requiresAuth': false}),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<UnauthorizedException>().having(
              (err) => err.message,
              'message',
              'Credenciales inválidas',
            ),
          ),
        ),
      );

      expect(sessionExpiredTriggered, isFalse);
      expect(await tokenStorage.getToken(), 'token_existente');
    });

    test('402 INSUFFICIENT_BALANCE mapea detalles de saldo requerido y disponible', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpAdapter(
        statusCode: 402,
        data: {
          'statusCode': 402,
          'error': 'Payment Required',
          'code': 'INSUFFICIENT_BALANCE',
          'message': 'Saldo insuficiente para confirmar el trabajo.',
          'details': {
            'requiredAmount': 50,
            'availableBalance': 15.5,
            'missingAmount': 34.5,
            'currency': 'MXN',
          },
        },
      );
      dio.interceptors.add(ErrorHandlerInterceptor());

      try {
        await dio.patch('/jobs/123/confirm');
        fail('Debió lanzar DioException');
      } on DioException catch (e) {
        expect(e.error, isA<InsufficientBalanceException>());
        final err = e.error as InsufficientBalanceException;
        expect(err.statusCode, 402);
        expect(err.errorCode, 'INSUFFICIENT_BALANCE');
        expect(err.requiredAmount, 50.0);
        expect(err.availableBalance, 15.5);
        expect(err.missingAmount, 34.5);
        expect(err.currency, 'MXN');
      }
    });

    test('403 envuelve con ForbiddenException', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpAdapter(
        statusCode: 403,
        data: {'message': 'Solo los especialistas pueden registrar conocimientos'},
      );
      dio.interceptors.add(ErrorHandlerInterceptor());

      try {
        await dio.put('/users/me/knowledge');
        fail('Debió lanzar DioException');
      } on DioException catch (e) {
        expect(e.error, isA<ForbiddenException>());
        expect((e.error as ForbiddenException).statusCode, 403);
      }
    });

    test('500 envuelve con ServerErrorException', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpAdapter(
        statusCode: 500,
        data: {'message': 'Error interno del servidor'},
      );
      dio.interceptors.add(ErrorHandlerInterceptor());

      try {
        await dio.get('/search/specialists');
        fail('Debió lanzar DioException');
      } on DioException catch (e) {
        expect(e.error, isA<ServerErrorException>());
        expect((e.error as ServerErrorException).statusCode, 500);
      }
    });

    test('400 con lista de mensajes de class-validator se une en BadRequestException', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpAdapter(
        statusCode: 400,
        data: {
          'statusCode': 400,
          'message': [
            'El correo electrónico debe ser una dirección válida',
            'La contraseña es requerida',
          ],
          'error': 'Bad Request',
        },
      );
      dio.interceptors.add(ErrorHandlerInterceptor());

      try {
        await dio.post('/auth/login');
        fail('Debió lanzar DioException');
      } on DioException catch (e) {
        expect(e.error, isA<BadRequestException>());
        expect(
          (e.error as BadRequestException).message,
          'El correo electrónico debe ser una dirección válida, La contraseña es requerida',
        );
      }
    });
  });

  group('ApiClient.unwrapData', () {
    test('desenvuelve el campo data de ResponseInterceptor conservando paginación', () {
      final wrapped = {
        'data': {
          'data': [
            {'id': 'tx-1', 'monto': 250.0},
          ],
          'meta': {
            'total': 1,
            'page': 1,
            'limit': 10,
            'totalPages': 1,
          },
        },
      };

      final unwrapped = ApiClient.unwrapData(wrapped) as Map<String, dynamic>;
      expect(unwrapped['data'], isA<List>());
      expect((unwrapped['data'] as List).length, 1);
      expect(unwrapped['meta']['totalPages'], 1);
    });
  });
}
