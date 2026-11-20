import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/ai/presentation/screens/ai_assistant_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/chat/domain/models/chat_models.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/jobs/presentation/screens/jobs_screen.dart';
import '../../features/kyc/presentation/screens/kyc_screen.dart';
import '../../features/search/domain/models/search_models.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/search/presentation/screens/specialist_detail_screen.dart';
import '../../features/users/presentation/screens/profile_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../utils/navigation_keys.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';

/// Construye el enrutador principal con protección por sesión JWT y shell adaptativo.
GoRouter createAppRouter({
  AuthProvider? authProvider,
  String? initialLocation,
}) {
  final defaultStart = initialLocation ??
      (authProvider?.isAuthenticated == true
          ? AppRoutes.dashboard
          : AppRoutes.login);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: defaultStart,
    refreshListenable: authProvider,
    redirect: (context, state) {
      if (authProvider == null) return null;

      final loggedIn = authProvider.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute =
          location == AppRoutes.login || location == AppRoutes.register;

      if (!loggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (loggedIn && isAuthRoute) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        builder: (context, state) => LoginScreen(
          prefilledEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: AppRouteNames.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.search,
            name: AppRouteNames.search,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.catalog,
            name: AppRouteNames.catalog,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CatalogScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.chat,
            name: AppRouteNames.chat,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.wallet,
            name: AppRouteNames.wallet,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WalletScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.jobs,
            name: AppRouteNames.jobs,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JobsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: AppRouteNames.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.chatRoom,
        name: AppRouteNames.chatRoom,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final extraRoom =
              state.extra is ChatRoomModel ? state.extra as ChatRoomModel : null;
          return ChatRoomScreen(
            roomId: roomId,
            initialRoom: extraRoom,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.specialistDetail,
        name: AppRouteNames.specialistDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final preview = state.extra is SpecialistSearchItemModel
              ? state.extra as SpecialistSearchItemModel
              : null;
          return SpecialistDetailScreen(
            specialistId: id,
            preview: preview,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.kyc,
        name: AppRouteNames.kyc,
        builder: (context, state) => const KycScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.aiAssistant,
        name: AppRouteNames.aiAssistant,
        builder: (context, state) => const AiAssistantScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('ManoLocal')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ruta no encontrada'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
