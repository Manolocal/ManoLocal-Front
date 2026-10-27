import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  /// Permite sobrescribir la URL base mediante --dart-define=API_URL=https://mi-api.com
  static const String _envBaseUrl = String.fromEnvironment('API_URL');

  /// URL base por defecto para el entorno de desarrollo local (NestJS normalmente corre en puerto 3000)
  /// En Android Emulator: 10.0.2.2 redirige al localhost de la máquina host.
  /// En Web, iOS y Desktop: localhost.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Storage Keys
  static const String tokenKey = 'jwt_auth_token';
  static const String refreshTokenKey = 'jwt_refresh_token';
  static const String userKey = 'cached_user_data';

  // Endpoints sugeridos de NestJS
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/profile';
  static const String refreshTokenEndpoint = '/auth/refresh';
}
