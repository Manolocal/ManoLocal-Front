import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/navigation_keys.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _testApiCall(BuildContext context, String endpoint) async {
    final apiClient = context.read<ApiClient>();
    try {
      final res = await apiClient.get(endpoint);
      GlobalNotifier.showSuccessSnackBar('Respuesta exitosa (${res.statusCode}): ${res.data}');
    } catch (_) {
      // El ErrorHandlerInterceptor ya maneja los snackbars para 401, 403, 500 y errores de conexión
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard ManoLocal'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Ir a Perfil',
            onPressed: () => context.go('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner de bienvenida
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.dashboard, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.user != null
                                  ? 'Bienvenido, ${authProvider.user!.name}'
                                  : 'Modo Desarrollo / Invitado',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Arquitectura por capas lista (UI, Dominio, Datos)',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Text(
                    'Estado de API NestJS:',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ApiConstants.baseUrl,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sección de comprobación del cliente HTTP e Interceptores
          Text(
            'Pruebas del Cliente HTTP e Interceptores',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba la captura centralizada de errores (401, 403, 500) y la inyección de JWT:',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _testApiCall(context, '/test/200'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Probar GET 200'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _testApiCall(context, '/test/401'),
                icon: const Icon(Icons.lock_clock),
                label: const Text('Simular 401 (Logout)'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _testApiCall(context, '/test/403'),
                icon: const Icon(Icons.block),
                label: const Text('Simular 403 (Forbidden)'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _testApiCall(context, '/test/500'),
                icon: const Icon(Icons.warning_amber),
                label: const Text('Simular 500 (Server Error)'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Accesos rápidos
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mi Perfil'),
              subtitle: const Text('Ver datos del usuario y sesión'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.go('/profile'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Volver a Pantalla de Login'),
              subtitle: const Text('Comprobar formulario de inicio de sesión'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.go('/login'),
            ),
          ),
        ],
      ),
    );
  }
}
