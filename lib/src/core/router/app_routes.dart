/// Rutas declaradas en el enrutador principal (`go_router`).
class AppRoutes {
  AppRoutes._();

  // Autenticación
  static const String login = '/login';
  static const String register = '/register';

  // Navegación principal (Shell)
  static const String dashboard = '/dashboard';
  static const String search = '/search';
  static const String catalog = '/catalog';
  static const String chat = '/chat';
  static const String wallet = '/wallet';
  static const String jobs = '/jobs';
  static const String profile = '/profile';

  // Pantallas de detalle y flujos guiados
  static const String chatRoom = '/chat/:roomId';
  static const String specialistDetail = '/specialist/:id';
  static const String kyc = '/kyc';
  static const String aiAssistant = '/ai-assistant';

  static String chatRoomPath(String roomId) => '/chat/$roomId';
  static String specialistDetailPath(String specialistId) =>
      '/specialist/$specialistId';
}

/// Nombres simbólicos para navegación con `context.goNamed(...)`.
class AppRouteNames {
  AppRouteNames._();

  static const String login = 'login';
  static const String register = 'register';
  static const String dashboard = 'dashboard';
  static const String search = 'search';
  static const String catalog = 'catalog';
  static const String chat = 'chat';
  static const String chatRoom = 'chat-room';
  static const String wallet = 'wallet';
  static const String jobs = 'jobs';
  static const String profile = 'profile';
  static const String specialistDetail = 'specialist-detail';
  static const String kyc = 'kyc';
  static const String aiAssistant = 'ai-assistant';
}
