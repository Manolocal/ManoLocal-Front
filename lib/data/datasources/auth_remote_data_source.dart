import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login({required String email, required String password});
  Future<UserModel> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthResponse> login({required String email, required String password}) async {
    final response = await apiClient.post(
      ApiConstants.loginEndpoint,
      data: {
        'email': email,
        'password': password,
      },
      // El login no necesita token previo
      options: Options(extra: {'requiresAuth': false}),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return AuthResponse.fromJson(data);
    }
    throw FormatException('Formato de respuesta inválido: $data');
  }

  @override
  Future<UserModel> getProfile() async {
    final response = await apiClient.get(ApiConstants.profileEndpoint);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final userJson = data['user'] ?? data['data'] ?? data;
      return UserModel.fromJson(userJson as Map<String, dynamic>);
    }
    throw FormatException('Formato de perfil inválido: $data');
  }
}
