import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/token_storage_service.dart';
import 'dio_interceptor.dart';
import 'error_handler.dart';

/// Cliente HTTP base estandarizado para comunicarse con la API de NestJS
class ApiClient {
  final Dio dio;

  ApiClient._({required this.dio});

  factory ApiClient.create({
    required TokenStorageService tokenStorage,
    OnSessionExpired? onSessionExpired,
    String? customBaseUrl,
  }) {
    final baseOptions = BaseOptions(
      baseUrl: customBaseUrl ?? ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
    );

    final dio = Dio(baseOptions);

    // 1. Interceptor de Autenticación (Inyecta JWT en cabeceras)
    dio.interceptors.add(
      DioAuthInterceptor(tokenStorage: tokenStorage),
    );

    // 2. Interceptor de Manejo Centralizado de Errores (401, 403, 500)
    dio.interceptors.add(
      ErrorHandlerInterceptor(
        tokenStorage: tokenStorage,
        onSessionExpired: onSessionExpired,
      ),
    );

    // 3. Logger de peticiones (en modo debug)
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrint('[HTTP] $obj'),
        ),
      );
    }

    return ApiClient._(dio: dio);
  }

  // Métodos convenientes estandarizados
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
}
