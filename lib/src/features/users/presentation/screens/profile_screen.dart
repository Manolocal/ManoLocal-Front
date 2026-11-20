import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/token_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/navigation_keys.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Pantalla base para la ruta `/profile` conectada a `AuthProvider`, `ProfileProvider`
/// y `TokenStorageService`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _storedToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await context.read<TokenStorageService>().getToken();
    if (!mounted) return;
    setState(() => _storedToken = token);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final theme = Theme.of(context);

    final userMe = profileProvider.userMe;
    final authUser = authProvider.user;

    final displayName = userMe?.displayName ?? authUser?.displayName ?? 'Invitado';
    final email = userMe?.email ?? authUser?.email ?? 'Sin sesión iniciada';
    final role = userMe?.role ?? authUser?.role;
    final status = userMe?.status ?? authUser?.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al Dashboard',
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sincronizar /users/me',
            onPressed: profileProvider.isLoading
                ? null
                : () async {
                    await profileProvider.loadProfile();
                    await _loadToken();
                  },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.gray,
                    child: Icon(Icons.person, size: 42, color: AppColors.yellow),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.grayMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _PillBadge(
                        label: role?.label ?? 'Sin rol',
                        backgroundColor: AppColors.gray,
                        foregroundColor: AppColors.yellow,
                      ),
                      _PillBadge(
                        label: status?.label ?? UserStatus.inactivo.label,
                        backgroundColor: AppColors.silverLight,
                        foregroundColor: AppColors.gray,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos Personales y KYC (/users/me)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    label: 'Teléfono',
                    value: userMe?.profile?.phone ?? 'Pendiente',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Dirección',
                    value: userMe?.profile?.address ?? 'Pendiente',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Código Postal',
                    value: userMe?.profile?.postalCode ?? 'Pendiente',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Oficios registrados',
                    value: userMe?.knowledges.isNotEmpty == true
                        ? userMe!.knowledges.map((k) => k.name).join(', ')
                        : 'Ninguno',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.key_outlined, color: AppColors.gray),
                      const SizedBox(width: 8),
                      Text(
                        'Token JWT en Almacenamiento Local',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _storedToken != null && _storedToken!.isNotEmpty
                        ? '${_storedToken!.substring(0, _storedToken!.length > 28 ? 28 : _storedToken!.length)}... (inyectado por DioAuthInterceptor)'
                        : 'No hay token JWT guardado actualmente.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: _storedToken != null
                          ? AppColors.success
                          : AppColors.grayMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.vpn_key_outlined),
                        label: const Text('Guardar Token Demo'),
                        onPressed: () async {
                          await context.read<TokenStorageService>().saveToken(
                                'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.demo_token',
                              );
                          await _loadToken();
                          GlobalNotifier.showSuccessSnackBar(
                            'Token JWT guardado para pruebas de interceptor.',
                          );
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('Consultar /users/me'),
                        onPressed: profileProvider.isLoading
                            ? null
                            : () => profileProvider.loadProfile(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.logout),
            label: Text(
              authProvider.isAuthenticated
                  ? 'Cerrar Sesión'
                  : 'Ir a Iniciar Sesión',
            ),
            onPressed: () async {
              if (authProvider.isAuthenticated) {
                await authProvider.logout();
                profileProvider.clear();
              }
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _PillBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.gray,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.grayMuted),
          ),
        ),
      ],
    );
  }
}
