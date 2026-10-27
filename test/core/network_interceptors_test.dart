import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manolocal_front/core/network/network_exceptions.dart';
import 'package:manolocal_front/core/services/token_storage_service.dart';
import 'package:manolocal_front/src/core/network/dio_interceptor.dart';
import 'package:manolocal_front/src/core/network/error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adapter de prueba para simular respuestas y errores HTTP en Dio
class MockHttpAdapter implements HttpClientAdapter {
  final int statusCode;
  final Map<String, dynamic> data;

  MockHttpAdapter({required this.statusCode, required this.data});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final jsonStr = jsonEncode(data);
    return ResponseBody.fromString(
      jsonStr,
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
    test('Inyecta cabecera Authorization con el token JWT cuando existe', () async {
      await tokenStorage.saveToken('jwt_super_secret_token_123');

      final interceptor = DioAuthInterceptor(tokenStorage: tokenStorage);
      final options = RequestOptions(path: '/users');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer jwt_super_secret_token_123');
      expect(options.headers['Content-Type'], 'application/json');
    });

    test('No inyecta cabecera Authorization si requiresAuth es false', () async {
      await tokenStorage.saveToken('jwt_super_secret_token_123');

      final interceptor = DioAuthInterceptor(tokenStorage: tokenStorage);
      final options = RequestOptions(
        path: '/auth/login',
        extra: {'requiresAuth': false},
      );
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], isNull);
    });
  });

  group('ErrorHandlerInterceptor', () {
    test('Interpreta 401, limpia el token y llama a onSessionExpired', () async {
      await tokenStorage.saveToken('token_para_borrar');
      bool sessionExpiredTriggered = false;

      final dio = Dio();
      dio.httpClientAdapter = MockHttpAdapter(
        statusCode: 401,
        data: {'message': 'Unauthorized'},
      );

      dio.interceptors.add(
        ErrorHandlerInterceptor(
          tokenStorage: tokenStorage,
          onSessionExpired: () {
            sessionExpiredTriggered = true;
          },
        ),
      );

      try {
        await dio.get('/profile');
      } on DioException catch (e) {
        expect(e.error, isA<UnauthorizedException>());
      }

      expect(sessionExpiredTriggered, isTrue);
      // Permitir que el microtask termine
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final storedToken = await tokenStorage.getToken();
      expect(storedToken, isNull);
    });

    test('Interpreta 403 y envuelve con ForbiddenException', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockHttpAdapter(
        statusCode: 403,
        data: {'message': 'Forbidden resource'},
      );

      dio.interceptors.add(ErrorHandlerInterceptor());

      try {
        await dio.get('/admin');
      } on DioException catch (e) {
        expect(e.error, isA<ForbiddenException>());
        expect((e.error as ForbiddenException).statusCode, 403);
      }
    });

    test('Interpreta 500 y mapea error de servidor', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockHttpAdapter(
        statusCode: 500,
        data: {'message': 'Database connection error'},
      );

      dio.interceptors.add(ErrorHandlerInterceptor());

      try {
        await dio.get('/items');
      } on DioException catch (e) {
        expect(e.error, isA<ServerErrorException>());
        expect((e.error as ServerErrorException).statusCode, 500);
      }
    });
  });
}
