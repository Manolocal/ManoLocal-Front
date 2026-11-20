import '../../../../core/enums/backend_enums.dart';
import '../models/auth_models.dart';

/// Contrato de repositorio para el módulo de Autenticación (flujo 2FA + JWT).
abstract class AuthRepository {
  Future<AuthUserModel> register(RegisterRequestModel request);

  /// Paso 1 del login: valida credenciales y dispara envío de PIN 2FA por correo.
  Future<LoginTwoFactorChallengeModel> login({
    required String email,
    required String password,
  });

  /// Paso 2 del login: verifica PIN 2FA de 6 dígitos y persiste el JWT.
  Future<AuthSessionModel> verify2fa({
    required String email,
    required String code,
  });

  Future<AuthUserModel> getAuthProfile();

  Future<RoleAccessResponseModel> checkRoleAccess(UserRole role);

  Future<AuthUserModel?> getCurrentUser();

  Future<bool> isAuthenticated();

  Future<void> logout();
}
