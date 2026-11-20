import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

/// Pantalla base para la ruta `/login` integrada con el flujo 2FA de ManoLocal-Back.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _twoFactorController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _submitTwoFactor(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authProvider.verify2fa(
      code: _twoFactorController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final awaiting2fa = authProvider.isAwaitingTwoFactor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ManoLocal · Acceso'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.dashboard),
            icon: const Icon(Icons.dashboard_outlined, color: AppColors.yellow),
            label: const Text(
              'Dashboard',
              style: TextStyle(color: AppColors.silver),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(theme, awaiting2fa, authProvider),
                        const SizedBox(height: 24),
                        if (authProvider.errorMessage != null) ...[
                          _StatusBanner(
                            message: authProvider.errorMessage!,
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.white,
                            icon: Icons.error_outline,
                          ),
                          const SizedBox(height: 16),
                        ] else if (authProvider.infoMessage != null) ...[
                          _StatusBanner(
                            message: authProvider.infoMessage!,
                            backgroundColor: AppColors.yellowSoft,
                            foregroundColor: AppColors.gray,
                            icon: Icons.mark_email_read_outlined,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          enabled: !awaiting2fa && !authProvider.isLoading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            hintText: 'usuario@manolocal.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa tu correo electrónico';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (!awaiting2fa) ...[
                          TextFormField(
                            controller: _passwordController,
                            enabled: !authProvider.isLoading,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () => _submitLogin(authProvider),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.gray,
                                    ),
                                  )
                                : const Text('Continuar (Enviar PIN 2FA)'),
                          ),
                        ] else ...[
                          TextFormField(
                            controller: _twoFactorController,
                            enabled: !authProvider.isLoading,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'Código 2FA (6 dígitos)',
                              hintText: '123456',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                            ),
                            validator: (value) {
                              final code = value?.trim() ?? '';
                              if (code.length != 6) {
                                return 'El código 2FA debe tener 6 dígitos';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () => _submitTwoFactor(authProvider),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.gray,
                                    ),
                                  )
                                : const Text('Verificar 2FA e Iniciar Sesión'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () {
                                    _twoFactorController.clear();
                                    authProvider.resetTwoFactor();
                                  },
                            child: const Text('Usar otra cuenta'),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.go(AppRoutes.dashboard),
                          icon: const Icon(Icons.explore_outlined),
                          label: const Text('Explorar Dashboard (Vista base)'),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => context.go(AppRoutes.profile),
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Ir a Perfil (Ruta base)'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    bool awaiting2fa,
    AuthProvider authProvider,
  ) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            color: AppColors.gray,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.handshake_rounded,
            size: 34,
            color: AppColors.yellow,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ManoLocal',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.gray,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          awaiting2fa
              ? 'Ingresa el PIN enviado a ${authProvider.pendingEmail ?? 'tu correo'}'
              : 'Conecta empleadores y especialistas locales',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.grayMuted,
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  const _StatusBanner({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
