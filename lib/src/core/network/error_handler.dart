import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:manolocal_front/core/network/network_exceptions.dart';
import 'package:manolocal_front/core/services/token_storage_service.dart';
import 'package:manolocal_front/core/utils/navigation_keys.dart';

/// Callback para ejecutar acciones de cierre de sesión centralizado
typedef OnSessionExpired = void Function();

/// Manejador de errores global que intercepta errores HTTP (DioException)
/// y ejecuta acciones centralizadas para los códigos 401, 403 y 500.
class ErrorHandlerInterceptor extends Interceptor {
  final TokenStorageService? tokenStorage;
  final OnSessionExpired? onSessionExpired;

  ErrorHandlerInterceptor({
    this.tokenStorage,
    this.onSessionExpired,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final responseData = err.response?.data;

    // Extrae el mensaje de error si la API de NestJS lo devolvió en { message: ... }
    String? apiMessage;
    if (responseData is Map && responseData['message'] != null) {
      final msg = responseData['message'];
      if (msg is List) {
        apiMessage = msg.join(', ');
      } else {
        apiMessage = msg.toString();
      }
    }

    AppException appException;

    switch (statusCode) {
      case 401:
        // [401 Unauthorized]: Sesión expirada o token inválido
        debugPrint('[ErrorHandler] 401 detectado -> Cerrando sesión...');
        unawaited(tokenStorage?.clearAll());
        onSessionExpired?.call();
        GlobalNotifier.showWarningSnackBar(
          apiMessage ?? 'Tu sesión ha expirado o no es válida. Inicia sesión nuevamente.',
        );
        appException = UnauthorizedException(
          message: apiMessage ?? 'No autorizado (401)',
          details: responseData,
        );
        break;

      case 403:
        // [403 Forbidden]: Sin permisos suficientes
        debugPrint('[ErrorHandler] 403 detectado -> Acceso denegado');
        GlobalNotifier.showWarningSnackBar(
          apiMessage ?? 'Acceso denegado: No tienes permisos para realizar esta acción (403).',
        );
        appException = ForbiddenException(
          message: apiMessage ?? 'Prohibido (403)',
          details: responseData,
        );
        break;

      case 500:
      case 502:
      case 503:
      case 504:
        // [500 Internal Server Error]: Fallo del servidor NestJS
        debugPrint('[ErrorHandler] $statusCode detectado -> Error de servidor');
        GlobalNotifier.showErrorSnackBar(
          apiMessage ?? 'Error en el servidor ($statusCode). Por favor intenta de nuevo más tarde.',
        );
        appException = ServerErrorException(
          message: apiMessage ?? 'Error interno del servidor ($statusCode)',
          statusCode: statusCode,
          details: responseData,
        );
        break;

      case 400:
        appException = BadRequestException(
          message: apiMessage ?? 'Solicitud incorrecta (400). Revisa los datos enviados.',
          details: responseData,
        );
        break;

      case 404:
        appException = NotFoundException(
          message: apiMessage ?? 'Recurso no encontrado (404).',
          details: responseData,
        );
        break;

      default:
        // Manejo de errores por tipo de conexión (Timeouts, falta de internet)
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          GlobalNotifier.showErrorSnackBar('Tiempo de espera agotado al conectar con el servidor.');
          appException = const TimeoutNetworkException();
        } else if (err.type == DioExceptionType.connectionError) {
          GlobalNotifier.showErrorSnackBar(
            'No se pudo conectar a la API. Verifica que NestJS esté corriendo y accesible.',
          );
          appException = const NoInternetConnectionException();
        } else {
          appException = AppException(
            message: apiMessage ?? err.message ?? 'Ocurrió un error de red inesperado.',
            statusCode: statusCode,
            details: responseData,
          );
        }
        break;
    }

    // Continuamos pasando un DioException enriquecido con el AppException en el error
    final customDioError = err.copyWith(
      error: appException,
    );

    handler.next(customDioError);
  }
}
