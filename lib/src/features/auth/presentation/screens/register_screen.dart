import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/navigation_keys.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/auth_provider.dart';

/// Pantalla de registro de cuentas con selección de rol (Empleador / Especialista)
/// y validación en tiempo real de contraseña fuerte alineada con NestJS.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  UserRole _selectedRole = UserRole.empleador;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final ok = await auth.register(
      email: email,
      password: _passwordController.text,
      role: _selectedRole,
      name: _nameController.text.trim(),
    );

    if (ok && mounted) {
      GlobalNotifier.showSuccessSnackBar(
        'Cuenta creada. Inicia sesión para recibir tu PIN 2FA.',
      );
      context.go('${AppRoutes.login}?email=${Uri.encodeComponent(email)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final pwd = _passwordController.text;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta en ManoLocal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Elige cómo usarás ManoLocal',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tu experiencia y herramientas se adaptarán a tu rol.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _RoleSelectorCard(
                                title: 'Empleador',
                                subtitle: 'Busco especialistas cerca de mí',
                                icon: Icons.person_search_rounded,
                                selected: _selectedRole == UserRole.empleador,
                                onTap: () => setState(
                                  () => _selectedRole = UserRole.empleador,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RoleSelectorCard(
                                title: 'Especialista',
                                subtitle: 'Ofrezco mis servicios locales',
                                icon: Icons.handyman_rounded,
                                selected:
                                    _selectedRole == UserRole.especialista,
                                onTap: () => setState(
                                  () => _selectedRole = UserRole.especialista,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (auth.errorMessage != null) ...[
                          AppStatusBanner.error(auth.errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _nameController,
                          enabled: !auth.isLoading,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            hintText: 'Ej. Carlos Sánchez López',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 3) {
                              return 'Ingresa tu nombre completo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          enabled: !auth.isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            hintText: 'nombre@correo.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: AppValidators.email,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !auth.isLoading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Contraseña segura',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                          validator: AppValidators.strongPassword,
                        ),
                        const SizedBox(height: 10),
                        _PasswordChecklist(password: pwd),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmController,
                          enabled: !auth.isLoading,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(auth),
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        if (_selectedRole == UserRole.especialista) ...[
                          const SizedBox(height: 14),
                          AppStatusBanner.info(
                            'Al registrarte como Especialista se creará automáticamente tu Billetera Virtual.',
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed:
                              auth.isLoading ? null : () => _submit(auth),
                          icon: auth.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.gray,
                                  ),
                                )
                              : const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(
                            auth.isLoading
                                ? 'Creando cuenta...'
                                : 'Registrarme como ${_selectedRole.label}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '¿Ya tienes cuenta?',
                              style: theme.textTheme.bodySmall,
                            ),
                            TextButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () => context.go(AppRoutes.login),
                              child: const Text('Iniciar sesión'),
                            ),
                          ],
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
}

class _RoleSelectorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleSelectorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gray
              : (isDark ? AppColors.graySurface : AppColors.silverLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.yellow
                : (isDark ? AppColors.grayMuted : AppColors.silver),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: selected
                      ? AppColors.yellow
                      : (isDark ? AppColors.silver : AppColors.gray),
                  size: 26,
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.yellow,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                color: selected
                    ? AppColors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.3,
                color: selected ? AppColors.silver : AppColors.grayMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  final String password;

  const _PasswordChecklist({required this.password});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _RequirementChip(
          label: '8+ caracteres',
          met: AppValidators.hasMinLength(password),
        ),
        _RequirementChip(
          label: 'Mayúscula',
          met: AppValidators.hasUppercase(password),
        ),
        _RequirementChip(
          label: 'Minúscula',
          met: AppValidators.hasLowercase(password),
        ),
        _RequirementChip(
          label: 'Número',
          met: AppValidators.hasDigit(password),
        ),
        _RequirementChip(
          label: 'Símbolo (@\$!%*?&_-#)',
          met: AppValidators.hasSpecialChar(password),
        ),
      ],
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final String label;
  final bool met;

  const _RequirementChip({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: met ? AppColors.successSoft : AppColors.silverLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 13,
            color: met ? AppColors.success : AppColors.grayMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: met ? AppColors.success : AppColors.grayMuted,
            ),
          ),
        ],
      ),
    );
  }
}
