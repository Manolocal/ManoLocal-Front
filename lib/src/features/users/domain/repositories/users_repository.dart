import '../models/user_profile_models.dart';

/// Contrato de repositorio para la gestión del perfil y oficios del usuario.
abstract class UsersRepository {
  Future<UserMeModel> getMe();
  Future<UserMeModel> updateProfile(UpdateProfileRequestModel request);
  Future<List<KnowledgeModel>> updateKnowledge(List<String> knowledges);
}
