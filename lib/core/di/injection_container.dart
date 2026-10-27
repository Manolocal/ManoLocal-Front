import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../presentation/providers/auth_provider.dart';
import '../network/api_client.dart';
import '../router/app_router.dart';
import '../services/token_storage_service.dart';

class DependencyContainer {
  final SharedPreferences sharedPreferences;
  final TokenStorageService tokenStorageService;
  final ApiClient apiClient;
  final AuthLocalDataSource authLocalDataSource;
  final AuthRemoteDataSource authRemoteDataSource;
  final AuthRepository authRepository;
  final AuthProvider authProvider;

  DependencyContainer({
    required this.sharedPreferences,
    required this.tokenStorageService,
    required this.apiClient,
    required this.authLocalDataSource,
    required this.authRemoteDataSource,
    required this.authRepository,
    required this.authProvider,
  });

  /// Inicializa todas las dependencias asíncronas del proyecto
  static Future<DependencyContainer> init() async {
    // 1. Storage local
    final sharedPreferences = await SharedPreferences.getInstance();
    final tokenStorageService = SharedPreferencesTokenStorage(sharedPreferences);

    // 2. DataSources
    final authLocalDataSource = AuthLocalDataSourceImpl(
      tokenStorage: tokenStorageService,
      prefs: sharedPreferences,
    );

    // Declaramos authProvider y apiClient coordinados
    late AuthProvider authProvider;

    final apiClient = ApiClient.create(
      tokenStorage: tokenStorageService,
      onSessionExpired: () {
        authProvider.forceLogout();
        appRouter.go(AppRoutes.login);
      },
    );

    final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);

    // 3. Repositorio (Dominio <-> Datos)
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      localDataSource: authLocalDataSource,
    );

    // 4. State Management (Provider)
    authProvider = AuthProvider(authRepository: authRepository);

    // Inicializar comprobación de autenticación
    await authProvider.checkAuthStatus();

    return DependencyContainer(
      sharedPreferences: sharedPreferences,
      tokenStorageService: tokenStorageService,
      apiClient: apiClient,
      authLocalDataSource: authLocalDataSource,
      authRemoteDataSource: authRemoteDataSource,
      authRepository: authRepository,
      authProvider: authProvider,
    );
  }

  /// Lista de Providers inyectados en la raíz del árbol de Widgets
  List<SingleChildWidget> get providers => [
        Provider<SharedPreferences>.value(value: sharedPreferences),
        Provider<TokenStorageService>.value(value: tokenStorageService),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthLocalDataSource>.value(value: authLocalDataSource),
        Provider<AuthRemoteDataSource>.value(value: authRemoteDataSource),
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ];
}
