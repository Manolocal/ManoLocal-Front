import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/navigation_keys.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

/// Pantalla base para la ruta `/dashboard` que resume el estado de la arquitectura,
/// la conexión con NestJS y todos los módulos disponibles de ManoLocal-Back.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const List<_BackendModuleSummary> _backendModules = [
    _BackendModuleSummary(
      title: 'Auth (2FA + JWT)',
      endpoints: 'POST /auth/register · /login · /verify-2fa · GET /auth/profile',
      icon: Icons.security_outlined,
    ),
    _BackendModuleSummary(
      title: 'Usuarios & Perfiles',
      endpoints: 'GET /users/me · PATCH /users/me/profile · PUT /users/me/knowledge',
      icon: Icons.badge_outlined,
    ),
    _BackendModuleSummary(
      title: 'Verificación KYC',
      endpoints: 'POST /kyc/documents (multipart INE + Selfie)',
      icon: Icons.fact_check_outlined,
    ),
    _BackendModuleSummary(
      title: 'IA & OCR Gemini',
      endpoints: 'POST /ai/verify-document · GET /ai/status · POST /ai/generate-text',
      icon: Icons.auto_awesome_outlined,
    ),
    _BackendModuleSummary(
      title: 'Búsqueda SEPOMEX / Copomex',
      endpoints: 'GET /search/specialists · GET /search/geo-info/:cp',
      icon: Icons.location_searching_outlined,
    ),
    _BackendModuleSummary(
      title: 'Catálogo de Trabajos',
      endpoints: 'POST /catalog/images · GET /catalog/me · /specialist/:id',
      icon: Icons.photo_library_outlined,
    ),
    _BackendModuleSummary(
      title: 'Chat REST + Socket.IO',
      endpoints: 'POST/GET /chat/rooms · /messages · WS join_room / send_message',
      icon: Icons.chat_bubble_outline,
    ),
    _BackendModuleSummary(
      title: 'Billetera Virtual',
      endpoints: 'GET /wallet/balance · /transactions · POST /wallet/mock-recharge',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _BackendModuleSummary(
      title: r'Acuerdos de Trabajo ($50 MXN)',
      endpoints: 'POST /jobs · /me · PATCH /confirm · /complete · /cancel',
      icon: Icons.work_outline,
    ),
  ];

  Future<void> _testProtectedRoute(BuildContext context, String path) async {
    final apiClient = context.read<ApiClient>();
    try {
      final response = await apiClient.get(path);
      GlobalNotifier.showSuccessSnackBar(
        'Respuesta ${response.statusCode}: ${response.data}',
      );
    } catch (_) {
      // ErrorHandlerInterceptor ya muestra la alerta para 401/403/500 o error de red.
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard ManoLocal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Ir a Perfil',
            onPressed: () => context.go(AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Ir a Login',
            onPressed: () => context.go(AppRoutes.login),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildWelcomeCard(context, theme, authProvider),
          const SizedBox(height: 16),
          _buildConnectionCard(context, theme, dashboardProvider),
          const SizedBox(height: 20),
          Text(
            'Módulos Integrados desde ManoLocal-Back',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 10),
          ..._backendModules.map(
            (module) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.yellowSoft,
                    child: Icon(module.icon, color: AppColors.gray),
                  ),
                  title: Text(
                    module.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    module.endpoints,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.grayMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Navegación Base',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person, color: AppColors.gray),
              title: const Text('Perfil de Usuario'),
              subtitle: const Text('Consultar /users/me y token JWT local'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.go(AppRoutes.profile),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.login, color: AppColors.gray),
              title: const Text('Pantalla de Login (2FA)'),
              subtitle: const Text('Iniciar sesión o cambiar de usuario'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.go(AppRoutes.login),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    ThemeData theme,
    AuthProvider authProvider,
  ) {
    final user = authProvider.user;
    return Card(
      color: AppColors.gray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.construction_outlined,
                color: AppColors.gray,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user != null
                        ? 'Hola, ${user.displayName}'
                        : 'Estructura Base ManoLocal',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user != null
                        ? 'Rol activo: ${user.role.label}'
                        : 'Arquitectura modular por capas · UI / Dominio / Datos',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.silver,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    ThemeData theme,
    DashboardProvider dashboardProvider,
  ) {
    final reachable = dashboardProvider.isBackendReachable;
    final statusColor = reachable == null
        ? AppColors.grayMuted
        : (reachable ? AppColors.success : AppColors.error);
    final statusText = reachable == null
        ? 'Sin comprobar'
        : (reachable
            ? 'En línea: ${dashboardProvider.healthMessage ?? 'OK'}'
            : 'Sin conexión: ${dashboardProvider.lastError ?? 'Error'}');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente HTTP NestJS (Dio + Interceptores)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.silverLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Base URL: ${ApiConstants.baseUrl}\nSocket.IO: ${ApiConstants.socketUrl}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.gray,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (dashboardProvider.aiStatus != null) ...[
              const SizedBox(height: 6),
              Text(
                'Gemini AI (${dashboardProvider.aiStatus!.model}): '
                '${dashboardProvider.aiStatus!.isConfigured ? 'Configurado' : 'Modo Mock'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grayMuted,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: dashboardProvider.isChecking
                      ? null
                      : () => dashboardProvider.checkBackendHealth(),
                  icon: dashboardProvider.isChecking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gray,
                          ),
                        )
                      : const Icon(Icons.network_check),
                  label: const Text('Verificar Backend (GET /)'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _testProtectedRoute(context, ApiConstants.authProfile),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Probar /auth/profile'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackendModuleSummary {
  final String title;
  final String endpoints;
  final IconData icon;

  const _BackendModuleSummary({
    required this.title,
    required this.endpoints,
    required this.icon,
  });
}
