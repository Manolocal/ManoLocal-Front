import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/token_storage_service.dart';
import 'dio_interceptor.dart';
import 'error_handler.dart';

/// Cliente HTTP base estandarizado sobre Dio para consumir ManoLocal-Back (NestJS).
class ApiClient {
  final Dio dio;

  ApiClient._({required this.dio});

  factory ApiClient.create({
    required TokenStorageService tokenStorage,
    OnSessionExpired? onSessionExpired,
    String? customBaseUrl,
    HttpClientAdapter? httpClientAdapter,
  }) {
    final baseOptions = BaseOptions(
      baseUrl: customBaseUrl ?? ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: const {
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
    );

    final dio = Dio(baseOptions);

    if (httpClientAdapter != null) {
      dio.httpClientAdapter = httpClientAdapter;
    }

    dio.interceptors.add(
      DioAuthInterceptor(tokenStorage: tokenStorage),
    );

    dio.interceptors.add(
      ErrorHandlerInterceptor(
        tokenStorage: tokenStorage,
        onSessionExpired: onSessionExpired,
      ),
    );

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

  /// Extrae el payload real desde el envoltorio `{ "data": ... }` emitido por
  /// `ResponseInterceptor` en NestJS.
  static dynamic unwrapData(dynamic rawResponse) {
    if (rawResponse is Map<String, dynamic> && rawResponse.containsKey('data')) {
      return rawResponse['data'];
    }
    if (rawResponse is Map && rawResponse.containsKey('data')) {
      return rawResponse['data'];
    }
    return rawResponse;
  }

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

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      dio.patch<T>(
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

  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
}
