import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/auth_provider.dart';

/// Pantalla de inicio de sesión profesional integrada con el flujo 2FA + JWT de ManoLocal-Back.
class LoginScreen extends StatefulWidget {
  final String? prefilledEmail;

  const LoginScreen({super.key, this.prefilledEmail});

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
  void initState() {
    super.initState();
    if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
      _emailController.text = widget.prefilledEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _submitTwoFactor(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await auth.verify2fa(
      code: _twoFactorController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  Future<void> _resendCode(AuthProvider auth) async {
    if (_passwordController.text.isEmpty) {
      _twoFactorController.clear();
      auth.resetTwoFactor();
      return;
    }
    await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final awaiting2fa = auth.isAwaitingTwoFactor;

    return Scaffold(
      body: Column(
        children: [
          _AuthHeroBanner(
            title: awaiting2fa ? 'Verificación en 2 pasos' : 'Bienvenido de vuelta',
            subtitle: awaiting2fa
                ? 'Protegemos tu cuenta con un PIN único enviado a tu correo'
                : 'El oficio que necesitas, a la vuelta de tu calle',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _StepIndicator(isStepTwo: awaiting2fa),
                                const SizedBox(height: 20),
                                if (auth.errorMessage != null) ...[
                                  AppStatusBanner.error(auth.errorMessage!),
                                  const SizedBox(height: 16),
                                ] else if (auth.infoMessage != null) ...[
                                  AppStatusBanner.warning(auth.infoMessage!),
                                  const SizedBox(height: 16),
                                ],
                                TextFormField(
                                  controller: _emailController,
                                  enabled: !awaiting2fa && !auth.isLoading,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    labelText: 'Correo electrónico',
                                    hintText: 'nombre@correo.com',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: AppValidators.email,
                                ),
                                const SizedBox(height: 16),
                                if (!awaiting2fa) ...[
                                  TextFormField(
                                    controller: _passwordController,
                                    enabled: !auth.isLoading,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) => _submitLogin(auth),
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Mostrar contraseña'
                                            : 'Ocultar contraseña',
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
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
                                  const SizedBox(height: 22),
                                  FilledButton.icon(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () => _submitLogin(auth),
                                    icon: auth.isLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: AppColors.gray,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 19,
                                          ),
                                    label: Text(
                                      auth.isLoading
                                          ? 'Enviando código...'
                                          : 'Continuar con verificación 2FA',
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.silverLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.mark_email_unread_outlined,
                                          color: AppColors.gray,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Enviamos un PIN de 6 dígitos a ${auth.pendingEmail ?? _emailController.text.trim()}. Válido por 10 minutos.',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.gray,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _twoFactorController,
                                    enabled: !auth.isLoading,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 6,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 10,
                                    ),
                                    onFieldSubmitted: (_) =>
                                        _submitTwoFactor(auth),
                                    decoration: const InputDecoration(
                                      labelText: 'Código 2FA (6 dígitos)',
                                      hintText: '••••••',
                                      counterText: '',
                                      prefixIcon: Icon(
                                        Icons.verified_user_outlined,
                                      ),
                                    ),
                                    validator: (value) {
                                      final code = value?.trim() ?? '';
                                      if (code.length != 6) {
                                        return 'Ingresa los 6 dígitos del código 2FA';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  FilledButton.icon(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () => _submitTwoFactor(auth),
                                    icon: auth.isLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: AppColors.gray,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.lock_open_rounded,
                                            size: 19,
                                          ),
                                    label: Text(
                                      auth.isLoading
                                          ? 'Verificando...'
                                          : 'Verificar e Iniciar Sesión',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      TextButton.icon(
                                        onPressed: auth.isLoading
                                            ? null
                                            : () {
                                                _twoFactorController.clear();
                                                auth.resetTwoFactor();
                                              },
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Cambiar cuenta'),
                                      ),
                                      TextButton(
                                        onPressed: auth.isLoading
                                            ? null
                                            : () => _resendCode(auth),
                                        child: const Text('Reenviar código'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '¿Aún no tienes cuenta?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.grayMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () {
                                    auth.clearError();
                                    context.push(AppRoutes.register);
                                  },
                            child: const Text(
                              'Crear cuenta',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _TrustFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHeroBanner extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AuthHeroBanner({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.gray,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(
                    size: 46,
                    showWordmark: true,
                    lightWordmark: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.silver,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final bool isStepTwo;

  const _StepIndicator({required this.isStepTwo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepChip(
          number: '1',
          label: 'Credenciales',
          active: !isStepTwo,
          completed: isStepTwo,
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: isStepTwo ? AppColors.yellow : AppColors.silver,
          ),
        ),
        _StepChip(
          number: '2',
          label: 'Código 2FA',
          active: isStepTwo,
          completed: false,
        ),
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  final String number;
  final String label;
  final bool active;
  final bool completed;

  const _StepChip({
    required this.number,
    required this.label,
    required this.active,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final bg = completed
        ? AppColors.success
        : (active ? AppColors.yellow : AppColors.silverLight);
    final fg = completed
        ? AppColors.white
        : (active ? AppColors.gray : AppColors.grayMuted);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: completed
                ? const Icon(Icons.check, size: 14, color: AppColors.white)
                : Text(
                    number,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: active || completed ? FontWeight.w700 : FontWeight.w500,
            color: active || completed
                ? Theme.of(context).colorScheme.onSurface
                : AppColors.grayMuted,
          ),
        ),
      ],
    );
  }
}

class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: const [
        _TrustItem(icon: Icons.verified_user_outlined, label: 'Acceso 2FA'),
        _TrustItem(icon: Icons.badge_outlined, label: 'KYC Verificado'),
        _TrustItem(icon: Icons.location_on_outlined, label: 'Talento Local'),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.grayMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grayMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
