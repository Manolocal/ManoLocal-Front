import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/auth_models.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUserModel> register(RegisterRequestModel request);
  Future<LoginTwoFactorChallengeModel> login({
    required String email,
    required String password,
  });
  Future<AuthSessionModel> verify2fa({
    required String email,
    required String code,
  });
  Future<AuthUserModel> getAuthProfile();
  Future<RoleAccessResponseModel> checkRoleAccess(UserRole role);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthUserModel> register(RegisterRequestModel request) async {
    final response = await apiClient.post(
      ApiConstants.authRegister,
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': false}),
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return AuthUserModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /auth/register: $payload');
  }

  @override
  Future<LoginTwoFactorChallengeModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiConstants.authLogin,
      data: {
        'email': email.trim(),
        'password': password,
      },
      options: Options(extra: const {'requiresAuth': false}),
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return LoginTwoFactorChallengeModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /auth/login: $payload');
  }

  @override
  Future<AuthSessionModel> verify2fa({
    required String email,
    required String code,
  }) async {
    final response = await apiClient.post(
      ApiConstants.authVerify2fa,
      data: {
        'email': email.trim(),
        'code': code.trim(),
      },
      options: Options(extra: const {'requiresAuth': false}),
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return AuthSessionModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /auth/verify-2fa: $payload');
  }

  @override
  Future<AuthUserModel> getAuthProfile() async {
    final response = await apiClient.get(ApiConstants.authProfile);
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return AuthUserModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /auth/profile: $payload');
  }

  @override
  Future<RoleAccessResponseModel> checkRoleAccess(UserRole role) async {
    final endpoint = switch (role) {
      UserRole.admin => ApiConstants.authAdminOnly,
      UserRole.empleador => ApiConstants.authEmpleadorOnly,
      UserRole.especialista => ApiConstants.authEspecialistaOnly,
    };

    final response = await apiClient.get(endpoint);
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return RoleAccessResponseModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en $endpoint: $payload');
  }
}
