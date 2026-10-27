import '../../domain/models/user_model.dart';
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
  Future<UserModel> login({required String email, required String password}) async {
    final authResponse = await remoteDataSource.login(email: email, password: password);
    await localDataSource.saveToken(authResponse.accessToken);

    UserModel user;
    if (authResponse.user != null) {
      user = authResponse.user!;
    } else {
      // Si el endpoint de login sólo retorna el token, obtenemos el perfil
      user = await remoteDataSource.getProfile();
    }

    await localDataSource.saveUser(user);
    return user;
  }

  @override
  Future<void> logout() async {
    await localDataSource.clear();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // Primero intenta recuperar de caché local
    final cachedUser = await localDataSource.getUser();
    if (cachedUser != null) {
      return cachedUser;
    }

    // Si hay token pero no usuario en caché, consulta a la API
    final token = await localDataSource.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final remoteUser = await remoteDataSource.getProfile();
        await localDataSource.saveUser(remoteUser);
        return remoteUser;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await localDataSource.getToken();
    return token != null && token.isNotEmpty;
  }
}
