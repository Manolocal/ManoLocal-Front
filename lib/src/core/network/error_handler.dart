import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/token_storage_service.dart';
import '../utils/navigation_keys.dart';
import 'network_exceptions.dart';

/// Callback invocado cuando ocurre un 401 en una ruta protegida para cerrar sesión.
typedef OnSessionExpired = void Function();

/// Manejador global de errores HTTP que intercepta códigos 401, 403, 500 (y 400/402/404/409)
/// devueltos por `HttpExceptionFilter` en NestJS y ejecuta acciones centralizadas.
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

    String? apiMessage;
    String? errorCode;
    dynamic details;
    String? path;
    String? timestamp;

    if (responseData is Map) {
      final rawMessage = responseData['message'];
      if (rawMessage is List) {
        apiMessage = rawMessage.join(', ');
      } else if (rawMessage != null) {
        apiMessage = rawMessage.toString();
      }
      errorCode = responseData['code']?.toString();
      details = responseData['details'];
      path = responseData['path']?.toString();
      timestamp = responseData['timestamp']?.toString();
    }

    final bool requiresAuth = err.requestOptions.extra['requiresAuth'] ?? true;
    final AppException appException;

    switch (statusCode) {
      case 401:
        debugPrint('[ErrorHandler] 401 detectado (requiresAuth=$requiresAuth)');
        if (requiresAuth) {
          unawaited(tokenStorage?.clearAll());
          onSessionExpired?.call();
          GlobalNotifier.showWarningSnackBar(
            apiMessage ??
                'Tu sesión ha expirado o no es válida. Inicia sesión nuevamente.',
          );
        } else {
          GlobalNotifier.showWarningSnackBar(
            apiMessage ?? 'Credenciales o código de verificación inválidos.',
          );
        }
        appException = UnauthorizedException(
          message: apiMessage ?? 'No autorizado (401)',
          errorCode: errorCode,
          details: details ?? responseData,
          path: path,
          timestamp: timestamp,
        );
        break;

      case 402:
        debugPrint('[ErrorHandler] 402 detectado -> Saldo insuficiente');
        GlobalNotifier.showWarningSnackBar(
          apiMessage ?? 'Saldo disponible insuficiente para confirmar el trabajo.',
        );
        appException = InsufficientBalanceException(
          message: apiMessage ?? 'Saldo insuficiente (402)',
          errorCode: errorCode ?? 'INSUFFICIENT_BALANCE',
          details: details ?? responseData,
          path: path,
          timestamp: timestamp,
        );
        break;

      case 403:
        debugPrint('[ErrorHandler] 403 detectado -> Acceso denegado');
        GlobalNotifier.showWarningSnackBar(
          apiMessage ??
              'Acceso denegado: No tienes permisos suficientes para realizar esta acción (403).',
        );
        appException = ForbiddenException(
          message: apiMessage ?? 'Prohibido (403)',
          errorCode: errorCode,
          details: details ?? responseData,
          path: path,
          timestamp: timestamp,
        );
        break;

      case 500:
      case 502:
      case 503:
      case 504:
        debugPrint('[ErrorHandler] $statusCode detectado -> Error de servidor');
        GlobalNotifier.showErrorSnackBar(
          apiMessage ??
              'Error en el servidor ($statusCode). Por favor intenta de nuevo más tarde.',
        );
        appException = ServerErrorException(
          message: apiMessage ?? 'Error interno del servidor ($statusCode)',
          statusCode: statusCode,
          errorCode: errorCode,
          details: details ?? responseData,
          path: path,
          timestamp: timestamp,
        );
        break;

      case 400:
        appException = BadRequestException(
          message:
              apiMessage ?? 'Solicitud incorrecta (400). Revisa los datos enviados.',
          errorCode: errorCode,
          details: details ?? responseData,
          path: path,
          timestamp: timestamp,
        );
        break;

      case 404:
        appException = NotFoundException(
          message: apiMessage ?? 'Recurso no encontrado (404).',
          errorCode: errorCode,
          details: details ?? responseData,
          path: path,
          timestamp: timestamp,
        );
        break;

      case 409:
        appException = ConflictException(
          message: apiMessage ?? 'Conflicto con el estado actual del recurso (409).',
          errorCode: errorCode,
          details: details ?? responseData,
          path: path,
          timestamp: timestamp,
        );
        break;

      default:
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          GlobalNotifier.showErrorSnackBar(
            'Tiempo de espera agotado al conectar con el servidor.',
          );
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
            errorCode: errorCode,
            details: details ?? responseData,
            path: path,
            timestamp: timestamp,
          );
        }
        break;
    }

    handler.next(err.copyWith(error: appException));
  }
}
