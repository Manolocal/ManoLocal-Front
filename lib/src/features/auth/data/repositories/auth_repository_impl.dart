import '../../../../core/enums/backend_enums.dart';
import '../../domain/models/auth_models.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<AuthUserModel> register(RegisterRequestModel request) {
    return remoteDataSource.register(request);
  }

  @override
  Future<LoginTwoFactorChallengeModel> login({
    required String email,
    required String password,
  }) async {
    final challenge = await remoteDataSource.login(
      email: email,
      password: password,
    );
    await localDataSource.savePendingTwoFactorEmail(
      challenge.email.isNotEmpty ? challenge.email : email.trim(),
    );
    return challenge;
  }

  @override
  Future<AuthSessionModel> verify2fa({
    required String email,
    required String code,
  }) async {
    final session = await remoteDataSource.verify2fa(
      email: email,
      code: code,
    );
    await localDataSource.saveToken(session.accessToken);
    await localDataSource.saveUser(session.user);
    await localDataSource.clearPendingTwoFactorEmail();
    return session;
  }

  @override
  Future<AuthUserModel> getAuthProfile() async {
    final user = await remoteDataSource.getAuthProfile();
    await localDataSource.saveUser(user);
    return user;
  }

  @override
  Future<RoleAccessResponseModel> checkRoleAccess(UserRole role) {
    return remoteDataSource.checkRoleAccess(role);
  }

  @override
  Future<AuthUserModel?> getCurrentUser() async {
    final token = await localDataSource.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final cachedUser = await localDataSource.getUser();
    if (cachedUser != null) {
      return cachedUser;
    }

    try {
      return await getAuthProfile();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await localDataSource.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() {
    return localDataSource.clear();
  }
}
