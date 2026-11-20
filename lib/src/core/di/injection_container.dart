import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/ai/data/datasources/ai_remote_data_source.dart';
import '../../features/ai/data/repositories/ai_repository_impl.dart';
import '../../features/ai/domain/repositories/ai_repository.dart';
import '../../features/ai/presentation/providers/ai_provider.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/catalog/data/datasources/catalog_remote_data_source.dart';
import '../../features/catalog/data/repositories/catalog_repository_impl.dart';
import '../../features/catalog/domain/repositories/catalog_repository.dart';
import '../../features/catalog/presentation/providers/catalog_provider.dart';
import '../../features/chat/data/datasources/chat_remote_data_source.dart';
import '../../features/chat/data/datasources/chat_socket_service.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/jobs/data/datasources/jobs_remote_data_source.dart';
import '../../features/jobs/data/repositories/jobs_repository_impl.dart';
import '../../features/jobs/domain/repositories/jobs_repository.dart';
import '../../features/jobs/presentation/providers/jobs_provider.dart';
import '../../features/kyc/data/datasources/kyc_remote_data_source.dart';
import '../../features/kyc/data/repositories/kyc_repository_impl.dart';
import '../../features/kyc/domain/repositories/kyc_repository.dart';
import '../../features/kyc/presentation/providers/kyc_provider.dart';
import '../../features/reviews/data/datasources/reviews_remote_data_source.dart';
import '../../features/reviews/data/repositories/reviews_repository_impl.dart';
import '../../features/reviews/domain/repositories/reviews_repository.dart';
import '../../features/reviews/presentation/providers/reviews_provider.dart';
import '../../features/search/data/datasources/search_remote_data_source.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/presentation/providers/search_provider.dart';
import '../../features/users/data/datasources/users_remote_data_source.dart';
import '../../features/users/data/repositories/users_repository_impl.dart';
import '../../features/users/domain/repositories/users_repository.dart';
import '../../features/users/presentation/providers/profile_provider.dart';
import '../../features/wallet/data/datasources/wallet_remote_data_source.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/presentation/providers/wallet_provider.dart';
import '../network/api_client.dart';
import '../router/app_router.dart';
import '../router/app_routes.dart';
import '../services/token_storage_service.dart';
import '../theme/theme_provider.dart';

/// Service Locator global con GetIt para el grafo completo de dependencias.
final GetIt sl = GetIt.instance;

/// Inicializa todas las dependencias del núcleo y de los 9 módulos del backend.
Future<void> initDependencies({
  String? customBaseUrl,
  GoRouter? router,
  HttpClientAdapter? httpClientAdapter,
  bool enableSocket = true,
}) async {
  // 1. Core / Almacenamiento y Tema
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  sl.registerLazySingleton<TokenStorageService>(
    () => SharedPreferencesTokenStorage(sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<ThemeProvider>(
    () => ThemeProvider(sl<SharedPreferences>()),
  );

  // 2. Cliente HTTP centralizado (Dio + Auth Interceptor + Error Handler)
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient.create(
      tokenStorage: sl<TokenStorageService>(),
      customBaseUrl: customBaseUrl,
      httpClientAdapter: httpClientAdapter,
      onSessionExpired: () {
        if (sl.isRegistered<AuthProvider>()) {
          sl<AuthProvider>().forceLogout();
        }
        if (sl.isRegistered<ProfileProvider>()) {
          sl<ProfileProvider>().clear();
        }
        if (sl.isRegistered<ChatProvider>()) {
          sl<ChatProvider>().clear();
        }
        if (sl.isRegistered<JobsProvider>()) {
          sl<JobsProvider>().clear();
        }
        if (sl.isRegistered<WalletProvider>()) {
          sl<WalletProvider>().clear();
        }
        if (sl.isRegistered<CatalogProvider>()) {
          sl<CatalogProvider>().clear();
        }
        if (sl.isRegistered<SearchProvider>()) {
          sl<SearchProvider>().clear();
        }
        if (sl.isRegistered<KycProvider>()) {
          sl<KycProvider>().clear();
        }
        if (sl.isRegistered<AiProvider>()) {
          sl<AiProvider>().clear();
        }
        if (sl.isRegistered<ReviewsProvider>()) {
          sl<ReviewsProvider>().clear();
        }
        if (sl.isRegistered<GoRouter>()) {
          sl<GoRouter>().go(AppRoutes.login);
        }
      },
    ),
  );

  // 3. DataSources y Repositorios por módulo
  // Auth
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      tokenStorage: sl<TokenStorageService>(),
      prefs: sl<SharedPreferences>(),
    ),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
    ),
  );

  // Users
  sl.registerLazySingleton<UsersRemoteDataSource>(
    () => UsersRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<UsersRepository>(
    () => UsersRepositoryImpl(remoteDataSource: sl<UsersRemoteDataSource>()),
  );

  // KYC
  sl.registerLazySingleton<KycRemoteDataSource>(
    () => KycRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<KycRepository>(
    () => KycRepositoryImpl(remoteDataSource: sl<KycRemoteDataSource>()),
  );

  // AI
  sl.registerLazySingleton<AiRemoteDataSource>(
    () => AiRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<AiRepository>(
    () => AiRepositoryImpl(remoteDataSource: sl<AiRemoteDataSource>()),
  );

  // Search
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl<SearchRemoteDataSource>()),
  );

  // Catalog
  sl.registerLazySingleton<CatalogRemoteDataSource>(
    () => CatalogRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<CatalogRepository>(
    () => CatalogRepositoryImpl(
      remoteDataSource: sl<CatalogRemoteDataSource>(),
    ),
  );

  // Chat (REST + Socket.IO)
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl<ChatRemoteDataSource>()),
  );
  sl.registerLazySingleton<ChatSocketService>(
    () => ChatSocketService(
      tokenStorage: sl<TokenStorageService>(),
      enabled: enableSocket,
    ),
  );

  // Wallet
  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(remoteDataSource: sl<WalletRemoteDataSource>()),
  );

  // Jobs
  sl.registerLazySingleton<JobsRemoteDataSource>(
    () => JobsRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<JobsRepository>(
    () => JobsRepositoryImpl(remoteDataSource: sl<JobsRemoteDataSource>()),
  );

  // Reviews
  sl.registerLazySingleton<ReviewsRemoteDataSource>(
    () => ReviewsRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<ReviewsRepository>(
    () => ReviewsRepositoryImpl(
      remoteDataSource: sl<ReviewsRemoteDataSource>(),
    ),
  );

  // 4. Providers de Presentación (ChangeNotifier)
  sl.registerLazySingleton<AuthProvider>(
    () => AuthProvider(authRepository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ProfileProvider>(
    () => ProfileProvider(usersRepository: sl<UsersRepository>()),
  );
  sl.registerLazySingleton<DashboardProvider>(
    () => DashboardProvider(
      apiClient: sl<ApiClient>(),
      aiRepository: sl<AiRepository>(),
    ),
  );
  sl.registerLazySingleton<SearchProvider>(
    () => SearchProvider(
      searchRepository: sl<SearchRepository>(),
      catalogRepository: sl<CatalogRepository>(),
    ),
  );
  sl.registerLazySingleton<CatalogProvider>(
    () => CatalogProvider(catalogRepository: sl<CatalogRepository>()),
  );
  sl.registerLazySingleton<WalletProvider>(
    () => WalletProvider(walletRepository: sl<WalletRepository>()),
  );
  sl.registerLazySingleton<JobsProvider>(
    () => JobsProvider(jobsRepository: sl<JobsRepository>()),
  );
  sl.registerLazySingleton<ChatProvider>(
    () => ChatProvider(
      chatRepository: sl<ChatRepository>(),
      socketService: sl<ChatSocketService>(),
      jobsProvider: sl<JobsProvider>(),
    ),
  );
  sl.registerLazySingleton<KycProvider>(
    () => KycProvider(kycRepository: sl<KycRepository>()),
  );
  sl.registerLazySingleton<AiProvider>(
    () => AiProvider(aiRepository: sl<AiRepository>()),
  );
  sl.registerLazySingleton<ReviewsProvider>(
    () => ReviewsProvider(reviewsRepository: sl<ReviewsRepository>()),
  );

  // 5. Restaurar sesión previa si existe token guardado antes de crear el router
  await sl<AuthProvider>().checkAuthStatus();

  final appRouter = router ?? createAppRouter(authProvider: sl<AuthProvider>());
  sl.registerSingleton<GoRouter>(appRouter);
}

/// Reinicia el contenedor GetIt (útil en pruebas unitarias y de widgets).
Future<void> resetDependencies() async {
  if (sl.isRegistered<ChatSocketService>()) {
    sl<ChatSocketService>().dispose();
  }
  await sl.reset();
}

/// Lista de Providers inyectados en la raíz mediante `MultiProvider`.
List<SingleChildWidget> buildAppProviders() {
  return [
    Provider<TokenStorageService>.value(value: sl<TokenStorageService>()),
    Provider<ApiClient>.value(value: sl<ApiClient>()),
    Provider<AuthRepository>.value(value: sl<AuthRepository>()),
    Provider<UsersRepository>.value(value: sl<UsersRepository>()),
    Provider<KycRepository>.value(value: sl<KycRepository>()),
    Provider<AiRepository>.value(value: sl<AiRepository>()),
    Provider<SearchRepository>.value(value: sl<SearchRepository>()),
    Provider<CatalogRepository>.value(value: sl<CatalogRepository>()),
    Provider<ChatRepository>.value(value: sl<ChatRepository>()),
    Provider<WalletRepository>.value(value: sl<WalletRepository>()),
    Provider<JobsRepository>.value(value: sl<JobsRepository>()),
    Provider<ReviewsRepository>.value(value: sl<ReviewsRepository>()),
    ChangeNotifierProvider<ThemeProvider>.value(value: sl<ThemeProvider>()),
    ChangeNotifierProvider<AuthProvider>.value(value: sl<AuthProvider>()),
    ChangeNotifierProvider<ProfileProvider>.value(value: sl<ProfileProvider>()),
    ChangeNotifierProvider<DashboardProvider>.value(
      value: sl<DashboardProvider>(),
    ),
    ChangeNotifierProvider<SearchProvider>.value(value: sl<SearchProvider>()),
    ChangeNotifierProvider<CatalogProvider>.value(value: sl<CatalogProvider>()),
    ChangeNotifierProvider<WalletProvider>.value(value: sl<WalletProvider>()),
    ChangeNotifierProvider<JobsProvider>.value(value: sl<JobsProvider>()),
    ChangeNotifierProvider<ChatProvider>.value(value: sl<ChatProvider>()),
    ChangeNotifierProvider<KycProvider>.value(value: sl<KycProvider>()),
    ChangeNotifierProvider<AiProvider>.value(value: sl<AiProvider>()),
    ChangeNotifierProvider<ReviewsProvider>.value(
      value: sl<ReviewsProvider>(),
    ),
  ];
}
