import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/auth_models.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  awaitingTwoFactor,
  authenticated,
  unauthenticated,
}

/// Provider de estado de autenticación conectado al flujo 2FA + JWT de ManoLocal-Back.
class AuthProvider extends ChangeNotifier {
  final AuthRepository authRepository;

  AuthStatus _status = AuthStatus.initial;
  AuthUserModel? _user;
  String? _pendingEmail;
  String? _infoMessage;
  String? _errorMessage;

  AuthProvider({required this.authRepository});

  AuthStatus get status => _status;
  AuthUserModel? get user => _user;
  String? get pendingEmail => _pendingEmail;
  String? get infoMessage => _infoMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAwaitingTwoFactor => _status == AuthStatus.awaitingTwoFactor;

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final currentUser = await authRepository.getCurrentUser();
      if (currentUser != null) {
        _user = currentUser;
        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required UserRole role,
    String? name,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();

    try {
      await authRepository.register(
        RegisterRequestModel(
          email: email,
          password: password,
          role: role,
          name: name,
        ),
      );
      _infoMessage = 'Cuenta registrada correctamente. Ahora inicia sesión.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();

    try {
      final challenge = await authRepository.login(
        email: email,
        password: password,
      );
      _pendingEmail = challenge.email.isNotEmpty ? challenge.email : email.trim();
      _infoMessage = challenge.message;
      _status = AuthStatus.awaitingTwoFactor;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verify2fa({
    required String code,
    String? email,
  }) async {
    final targetEmail = (email ?? _pendingEmail)?.trim() ?? '';
    if (targetEmail.isEmpty) {
      _errorMessage = 'No hay un correo pendiente de verificación 2FA.';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await authRepository.verify2fa(
        email: targetEmail,
        code: code,
      );
      _user = session.user;
      _pendingEmail = null;
      _infoMessage = null;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _status = AuthStatus.awaitingTwoFactor;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await authRepository.logout();
    } finally {
      _user = null;
      _pendingEmail = null;
      _infoMessage = null;
      _errorMessage = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Invocado de forma centralizada por `ErrorHandlerInterceptor` ante un 401.
  void forceLogout() {
    _user = null;
    _pendingEmail = null;
    _infoMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void resetTwoFactor() {
    _pendingEmail = null;
    _infoMessage = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException && error.error is AppException) {
      return (error.error as AppException).message;
    }
    if (error is AppException) {
      return error.message;
    }
    return error.toString();
  }
}
