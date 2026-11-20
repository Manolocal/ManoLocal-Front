import 'package:flutter/foundation.dart';

/// Constantes de conexión HTTP y WebSocket alineadas con ManoLocal-Back (NestJS).
class ApiConstants {
  ApiConstants._();

  /// Permite sobrescribir la URL mediante --dart-define=API_URL=http://192.168.1.50:3000
  static const String _envBaseUrl = String.fromEnvironment('API_URL');
  static const String _envSocketUrl = String.fromEnvironment('SOCKET_URL');

  /// URL base local sin prefijo global (NestJS escucha directamente en :3000).
  /// En emulador Android usa 10.0.2.2 para alcanzar el localhost de la máquina host.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/')
          ? _envBaseUrl.substring(0, _envBaseUrl.length - 1)
          : _envBaseUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// URL del servidor Socket.IO (`ChatGateway`).
  static String get socketUrl {
    if (_envSocketUrl.isNotEmpty) {
      return _envSocketUrl.endsWith('/')
          ? _envSocketUrl.substring(0, _envSocketUrl.length - 1)
          : _envSocketUrl;
    }
    return baseUrl;
  }

  // Timeouts alineados con TimeoutInterceptor(30000) del backend
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Sistema
  static const String health = '/';

  // Auth (/auth)
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authVerify2fa = '/auth/verify-2fa';
  static const String authProfile = '/auth/profile';
  static const String authAdminOnly = '/auth/admin-only';
  static const String authEmpleadorOnly = '/auth/empleador-only';
  static const String authEspecialistaOnly = '/auth/especialista-only';

  // Users (/users)
  static const String usersMe = '/users/me';
  static const String usersMeProfile = '/users/me/profile';
  static const String usersMeKnowledge = '/users/me/knowledge';

  // KYC (/kyc)
  static const String kycDocuments = '/kyc/documents';

  // AI (/ai)
  static const String aiVerifyDocument = '/ai/verify-document';
  static String aiKnowledgeVerifications(String knowledgeId) =>
      '/ai/knowledge/$knowledgeId/verifications';
  static const String aiStatus = '/ai/status';
  static const String aiGenerateText = '/ai/generate-text';

  // Search (/search)
  static const String searchSpecialists = '/search/specialists';
  static String searchGeoInfo(String cp) => '/search/geo-info/$cp';

  // Catalog (/catalog)
  static const String catalogImages = '/catalog/images';
  static const String catalogMe = '/catalog/me';
  static String catalogSpecialist(String specialistId) =>
      '/catalog/specialist/$specialistId';
  static String catalogDeleteImage(String id) => '/catalog/images/$id';

  // Chat REST (/chat)
  static const String chatRooms = '/chat/rooms';
  static String chatRoomMessages(String roomId) => '/chat/rooms/$roomId/messages';
  static String chatRoomRead(String roomId) => '/chat/rooms/$roomId/read';

  // Wallet (/wallet)
  static const String wallet = '/wallet';
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletMockRecharge = '/wallet/mock-recharge';
  static const String walletRecharge = '/wallet/recharge';

  // Jobs (/jobs)
  static const String jobs = '/jobs';
  static const String jobsMe = '/jobs/me';
  static String jobsByRoom(String roomId) => '/jobs/room/$roomId';
  static String jobById(String id) => '/jobs/$id';
  static String jobConfirm(String id) => '/jobs/$id/confirm';
  static String jobComplete(String id) => '/jobs/$id/complete';
  static String jobCancel(String id) => '/jobs/$id/cancel';

  // Reviews (/reviews)
  static const String reviews = '/reviews';
  static String reviewsBySpecialist(String specialistId) =>
      '/reviews/specialist/$specialistId';
  static String reviewByJob(String jobAgreementId) =>
      '/reviews/job/$jobAgreementId';
}

/// Eventos Socket.IO expuestos por `ChatGateway` en ManoLocal-Back.
class SocketEvents {
  SocketEvents._();

  static const String joinRoom = 'join_room';
  static const String leaveRoom = 'leave_room';
  static const String sendMessage = 'send_message';
  static const String newMessage = 'new_message';
  static const String getMessages = 'get_messages';
  static const String createJob = 'create_job';
  static const String confirmJob = 'confirm_job';
  static const String completeJob = 'complete_job';
  static const String cancelJob = 'cancel_job';
  static const String jobCreated = 'job_created';
  static const String jobUpdated = 'job_updated';
}
