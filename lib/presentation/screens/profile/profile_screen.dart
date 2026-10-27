import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/token_storage_service.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final tokenStorage = context.read<TokenStorageService>();
    final theme = Theme.of(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.person, size: 48, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user?.name ?? 'Usuario Demo',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              user?.email ?? 'usuario@manolocal.com',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(height: 24),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de la Cuenta',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  _buildProfileRow('ID Usuario', user?.id.isNotEmpty == true ? user!.id : 'usr_local_001'),
                  const SizedBox(height: 12),
                  _buildProfileRow('Rol', user?.role ?? 'Cliente / Desarrollador'),
                  const SizedBox(height: 12),
                  _buildProfileRow(
                    'Estado de Autenticación',
                    authProvider.isAuthenticated ? 'Autenticado' : 'No autenticado / Invitado',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Comprobar token almacenado
          FutureBuilder<String?>(
            future: tokenStorage.getToken(),
            builder: (context, snapshot) {
              final token = snapshot.data;
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.key, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Token JWT en Almacenamiento Local',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        token != null && token.isNotEmpty
                            ? '${token.substring(0, token.length > 30 ? 30 : token.length)}... (Inyectado automáticamente por DioAuthInterceptor)'
                            : 'Ningún token guardado actualmente.',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: token != null ? Colors.green.shade700 : theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Guardar Token de Prueba'),
                        onPressed: () async {
                          await tokenStorage.saveToken('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.demo_token');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Token de prueba JWT guardado en SharedPreferences')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
