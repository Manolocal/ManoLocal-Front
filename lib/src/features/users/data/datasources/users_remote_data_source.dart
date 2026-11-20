import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/user_profile_models.dart';

abstract class UsersRemoteDataSource {
  Future<UserMeModel> getMe();
  Future<UserMeModel> updateProfile(UpdateProfileRequestModel request);
  Future<List<KnowledgeModel>> updateKnowledge(List<String> knowledges);
}

class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final ApiClient apiClient;

  UsersRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserMeModel> getMe() async {
    final response = await apiClient.get(ApiConstants.usersMe);
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return UserMeModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /users/me: $payload');
  }

  @override
  Future<UserMeModel> updateProfile(UpdateProfileRequestModel request) async {
    final response = await apiClient.patch(
      ApiConstants.usersMeProfile,
      data: request.toJson(),
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return UserMeModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /users/me/profile: $payload');
  }

  @override
  Future<List<KnowledgeModel>> updateKnowledge(List<String> knowledges) async {
    final response = await apiClient.put(
      ApiConstants.usersMeKnowledge,
      data: {'knowledges': knowledges},
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(KnowledgeModel.fromJson)
          .toList();
    }
    throw FormatException('Respuesta inválida en /users/me/knowledge: $payload');
  }
}
