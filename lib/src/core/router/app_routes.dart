/// Rutas declaradas en el enrutador principal (`go_router`).
class AppRoutes {
  AppRoutes._();

  // Rutas base activas
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';

  // Rutas futuras reservadas para los módulos de negocio del equipo
  static const String search = '/search';
  static const String catalog = '/catalog';
  static const String chat = '/chat';
  static const String wallet = '/wallet';
  static const String jobs = '/jobs';
  static const String kyc = '/kyc';
}

/// Nombres simbólicos para navegación con `context.goNamed(...)`.
class AppRouteNames {
  AppRouteNames._();

  static const String login = 'login';
  static const String dashboard = 'dashboard';
  static const String profile = 'profile';
}
