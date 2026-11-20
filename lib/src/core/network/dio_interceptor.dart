import 'package:dio/dio.dart';
import '../services/token_storage_service.dart';

/// Interceptor global de Dio encargado de inyectar automáticamente el token JWT
/// en la cabecera `Authorization` de todas las peticiones salientes hacia NestJS.
class DioAuthInterceptor extends Interceptor {
  final TokenStorageService tokenStorage;

  DioAuthInterceptor({required this.tokenStorage});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final bool requiresAuth = options.extra['requiresAuth'] ?? true;

    if (requiresAuth) {
      try {
        final token = await tokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {
        // Si falla la lectura del almacenamiento local, continuamos sin bloquear la petición.
      }
    }

    options.headers.putIfAbsent('Accept', () => 'application/json');

    // No sobrescribir el Content-Type cuando se envía multipart/form-data (KYC, AI, Catálogo).
    if (options.data is! FormData) {
      options.headers.putIfAbsent('Content-Type', () => 'application/json');
    }

    return handler.next(options);
  }
}
