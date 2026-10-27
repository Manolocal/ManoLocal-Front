import 'package:dio/dio.dart';
import 'package:manolocal_front/core/services/token_storage_service.dart';

/// Interceptor global de Dio encargado de inyectar automáticamente el token JWT
/// en las cabeceras de todas las peticiones salientes dirigidas a la API NestJS.
class DioAuthInterceptor extends Interceptor {
  final TokenStorageService tokenStorage;

  DioAuthInterceptor({required this.tokenStorage});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Si la petición indica explícitamente que no requiere autenticación
    final bool requiresAuth = options.extra['requiresAuth'] ?? true;

    if (requiresAuth) {
      try {
        final token = await tokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        // En caso de fallo al leer almacenamiento, continuamos la petición
      }
    }

    // Cabeceras estándares por defecto
    options.headers.putIfAbsent('Content-Type', () => 'application/json');
    options.headers.putIfAbsent('Accept', () => 'application/json');

    return handler.next(options);
  }
}
