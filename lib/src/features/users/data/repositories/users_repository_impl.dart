import '../../domain/models/user_profile_models.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_data_source.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource remoteDataSource;

  UsersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserMeModel> getMe() => remoteDataSource.getMe();

  @override
  Future<UserMeModel> updateProfile(UpdateProfileRequestModel request) {
    return remoteDataSource.updateProfile(request);
  }

  @override
  Future<List<KnowledgeModel>> updateKnowledge(List<String> knowledges) {
    return remoteDataSource.updateKnowledge(knowledges);
  }
}
