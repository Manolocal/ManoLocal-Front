import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/navigation_keys.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badges.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../../kyc/presentation/providers/kyc_provider.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/models/user_profile_models.dart';
import '../providers/profile_provider.dart';

/// Centro profesional de Perfil, Datos Personales, Oficios, Certificados OCR con IA y Preferencias.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> _suggestedTrades = [
    'Plomería residencial',
    'Electricista',
    'Carpintería',
    'Pintura y acabados',
    'Herrería',
    'Albañilería',
    'Instalación de A/C',
    'Cerrajería',
    'Jardinería',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<ProfileProvider>().loadProfile();
      }
    });
  }

  Future<void> _openEditProfileSheet(UserMeModel? userMe) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(
      text: userMe?.profile?.fullName ?? userMe?.name ?? '',
    );
    final phoneCtrl = TextEditingController(text: userMe?.profile?.phone ?? '');
    final addressCtrl =
        TextEditingController(text: userMe?.profile?.address ?? '');
    final cpCtrl =
        TextEditingController(text: userMe?.profile?.postalCode ?? '');
    String? detectedMunicipio;

    final request = await showModalBottomSheet<UpdateProfileRequestModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Editar datos personales',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tu código postal se utiliza para el geofiltro municipal SEPOMEX.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 3) {
                        return 'Ingresa tu nombre completo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (10 dígitos México) *',
                      hintText: '5512345678',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) => AppValidators.phoneMx(v, required: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dirección (Calle, número y colonia) *',
                      hintText: 'Av. Revolución 100, Col. San Ángel',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 5) {
                        return 'Ingresa tu dirección completa';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) async {
                      if (val.trim().length == 5) {
                        final geo = await context
                            .read<SearchProvider>()
                            .lookupGeoInfo(val.trim());
                        if (ctx.mounted) {
                          setModalState(() {
                            detectedMunicipio = geo?.municipio;
                          });
                        }
                      } else {
                        setModalState(() => detectedMunicipio = null);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Código Postal (5 dígitos) *',
                      hintText: '01000',
                      counterText: '',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) =>
                        AppValidators.postalCodeMx(v, required: true),
                  ),
                  if (detectedMunicipio != null &&
                      detectedMunicipio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Municipio SEPOMEX: $detectedMunicipio',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.of(ctx).pop(
                        UpdateProfileRequestModel(
                          fullName: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                          postalCode: cpCtrl.text.trim(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (request == null || !mounted) return;
    final ok = await context.read<ProfileProvider>().updateProfile(request);
    if (ok && mounted) {
      GlobalNotifier.showSuccessSnackBar('Perfil actualizado correctamente.');
    } else if (mounted) {
      final err = context.read<ProfileProvider>().errorMessage;
      if (err != null) GlobalNotifier.showErrorSnackBar(err);
    }
  }

  Future<void> _openEditKnowledgesSheet(List<KnowledgeModel> current) async {
    final selected = current.map((k) => k.name).toList();
    final customCtrl = TextEditingController();

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void addTrade(String raw) {
            final clean = raw.trim();
            if (clean.isEmpty) return;
            if (!selected.any((s) => s.toLowerCase() == clean.toLowerCase())) {
              setModalState(() => selected.add(clean));
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(ctx).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Mis oficios y conocimientos',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Los empleadores te encontrarán por los oficios que registres aquí.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Agregar oficio personalizado',
                            hintText: 'Ej. Reparación de boilers',
                          ),
                          onSubmitted: (val) {
                            addTrade(val);
                            customCtrl.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: () {
                            addTrade(customCtrl.text);
                            customCtrl.clear();
                          },
                          child: const Icon(Icons.add_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Seleccionados (${selected.length})',
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (selected.isEmpty)
                    Text(
                      'Agrega al menos un oficio para activar tu perfil.',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selected
                          .map(
                            (name) => InputChip(
                              label: Text(name),
                              onDeleted: () =>
                                  setModalState(() => selected.remove(name)),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Sugerencias populares',
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedTrades
                        .where(
                          (t) => !selected
                              .any((s) => s.toLowerCase() == t.toLowerCase()),
                        )
                        .map(
                          (trade) => ActionChip(
                            avatar: const Icon(Icons.add_rounded, size: 16),
                            label: Text(trade),
                            onPressed: () => addTrade(trade),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.of(ctx).pop(selected),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Guardar oficios'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == null || !mounted) return;
    final ok = await context.read<ProfileProvider>().updateKnowledge(result);
    if (ok && mounted) {
      GlobalNotifier.showSuccessSnackBar('Oficios actualizados correctamente.');
    } else if (mounted) {
      final err = context.read<ProfileProvider>().errorMessage;
      if (err != null) GlobalNotifier.showErrorSnackBar(err);
    }
  }

  Future<void> _verifyKnowledgeCertificate(KnowledgeModel knowledge) async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Selecciona tu certificado o diploma',
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      final aiProvider = context.read<AiProvider>();
      final verification = await aiProvider.verifyCertificate(
        knowledgeId: knowledge.id,
        filePath: file.path ?? '',
        bytes: bytes,
        fileName: file.name,
      );

      if (!mounted) return;
      if (verification != null) {
        await context.read<ProfileProvider>().loadProfile();
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  verification.status == DocumentVerificationStatus.validated
                      ? Icons.workspace_premium_rounded
                      : Icons.info_outline_rounded,
                  color: verification.status ==
                          DocumentVerificationStatus.validated
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('Resultado Gemini OCR')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DocumentVerificationBadge(
                  status: verification.status,
                  score: verification.score,
                ),
                const SizedBox(height: 12),
                if (verification.reason != null &&
                    verification.reason!.isNotEmpty)
                  Text(verification.reason!),
                if (verification.provider != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Motor: ${verification.provider}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else if (aiProvider.errorMessage != null) {
        GlobalNotifier.showErrorSnackBar(aiProvider.errorMessage!);
      }
    } catch (e) {
      GlobalNotifier.showErrorSnackBar(
        'No se pudo seleccionar el documento: $e',
      );
    }
  }

  Future<void> _showVerificationsHistory(KnowledgeModel knowledge) async {
    final list = await context
        .read<AiProvider>()
        .loadKnowledgeVerifications(knowledge.id);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verificaciones de "${knowledge.name}"',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Aún no has enviado diplomas o certificados para este oficio.',
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 14),
                  itemBuilder: (_, idx) {
                    final item = list[idx];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DocumentVerificationBadge(
                              status: item.status,
                              score: item.score,
                            ),
                            Text(
                              AppFormatters.dateTime(item.createdAt),
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (item.reason != null && item.reason!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(item.reason!, style: const TextStyle(fontSize: 13)),
                        ],
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Seguro que deseas salir de tu cuenta de ManoLocal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    context.read<ProfileProvider>().clear();
    context.read<ChatProvider>().clear();
    context.read<JobsProvider>().clear();
    context.read<WalletProvider>().clear();
    context.read<CatalogProvider>().clear();
    context.read<SearchProvider>().clear();
    context.read<KycProvider>().clear();
    context.read<AiProvider>().clear();
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final ai = context.watch<AiProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final userMe = profile.userMe;
    final displayName =
        userMe?.displayName ?? auth.user?.displayName ?? 'Usuario';
    final email = userMe?.email ?? auth.user?.email ?? '';
    final role = userMe?.role ?? auth.user?.role ?? UserRole.empleador;
    final status = userMe?.status ?? auth.user?.status ?? UserStatus.inactivo;
    final isSpecialist = role == UserRole.especialista;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            tooltip: 'Actualizar perfil',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: profile.isLoading ? null : () => profile.loadProfile(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gray,
        backgroundColor: AppColors.yellow,
        onRefresh: () => profile.loadProfile(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.gray,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          UserAvatar(
                            initials: AppFormatters.initials(displayName),
                            radius: 36,
                            highlighted: true,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: AppColors.silver,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              RoleBadge(role: role),
                              UserStatusBadge(status: status),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: 'Datos personales',
                      subtitle: 'Información usada para contacto y geofiltro',
                      actionLabel: 'Editar',
                      onAction: () => _openEditProfileSheet(userMe),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _ProfileFieldRow(
                              icon: Icons.badge_outlined,
                              label: 'Nombre',
                              value: userMe?.profile?.fullName ??
                                  userMe?.name ??
                                  'Pendiente',
                            ),
                            const Divider(height: 20),
                            _ProfileFieldRow(
                              icon: Icons.phone_outlined,
                              label: 'Teléfono',
                              value: userMe?.profile?.phone ?? 'Pendiente',
                            ),
                            const Divider(height: 20),
                            _ProfileFieldRow(
                              icon: Icons.home_outlined,
                              label: 'Dirección',
                              value: userMe?.profile?.address ?? 'Pendiente',
                            ),
                            const Divider(height: 20),
                            _ProfileFieldRow(
                              icon: Icons.location_on_outlined,
                              label: 'Código Postal',
                              value: userMe?.profile?.postalCode ?? 'Pendiente',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader(
                      title: 'Identidad y Seguridad (KYC)',
                      subtitle: 'INE oficial + selfie verificada',
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: profile.isKycComplete
                                ? AppColors.successSoft
                                : AppColors.yellowSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            profile.isKycComplete
                                ? Icons.verified_user_rounded
                                : Icons.document_scanner_outlined,
                            color: profile.isKycComplete
                                ? AppColors.success
                                : AppColors.gray,
                          ),
                        ),
                        title: Text(
                          profile.isKycComplete
                              ? 'Documentos KYC cargados'
                              : 'Completar verificación KYC',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          profile.isKycComplete
                              ? 'Estado actual: ${status.label}'
                              : 'Sube tu INE y selfie para obtener tu insignia de confianza',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRoutes.kyc),
                      ),
                    ),
                    if (isSpecialist) ...[
                      const SizedBox(height: 22),
                      SectionHeader(
                        title: 'Oficios y Certificados con IA',
                        subtitle:
                            'Respalda tus habilidades con validación OCR Gemini',
                        actionLabel: 'Editar oficios',
                        onAction: () => _openEditKnowledgesSheet(
                          userMe?.knowledges ?? const [],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (ai.isVerifyingDocument)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: LinearProgressIndicator(),
                        ),
                      if (userMe == null || userMe.knowledges.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                const Text(
                                  'Aún no has registrado tus oficios.',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _openEditKnowledgesSheet(const []),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Agregar mis oficios'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...userMe.knowledges.map((knowledge) {
                          final latest = knowledge.verifications.isNotEmpty
                              ? knowledge.verifications.first
                              : null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.handyman_rounded,
                                          size: 20,
                                          color: AppColors.yellowDark,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            knowledge.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        if (latest != null)
                                          DocumentVerificationBadge(
                                            status: latest.status,
                                            score: latest.score,
                                          )
                                        else
                                          const AppPillBadge(
                                            label: 'Sin certificado',
                                            backgroundColor:
                                                AppColors.silverLight,
                                            foregroundColor:
                                                AppColors.grayMuted,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: ai.isVerifyingDocument
                                              ? null
                                              : () =>
                                                  _verifyKnowledgeCertificate(
                                                    knowledge,
                                                  ),
                                          icon: const Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Verificar certificado (PDF/Img)',
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _showVerificationsHistory(
                                                knowledge,
                                              ),
                                          icon: const Icon(
                                            Icons.history_rounded,
                                            size: 16,
                                          ),
                                          label: const Text('Historial'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                    const SizedBox(height: 22),
                    const SectionHeader(title: 'Accesos rápidos y preferencias'),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          if (isSpecialist) ...[
                            ListTile(
                              leading: const Icon(Icons.work_outline_rounded),
                              title: const Text('Mis acuerdos de trabajo'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context.go(AppRoutes.jobs),
                            ),
                            const Divider(height: 1),
                          ],
                          if (role == UserRole.admin) ...[
                            ListTile(
                              leading: const Icon(
                                Icons.account_balance_wallet_outlined,
                              ),
                              title: const Text('Billetera Virtual'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context.go(AppRoutes.wallet),
                            ),
                            const Divider(height: 1),
                          ],
                          ListTile(
                            leading: const Icon(
                              Icons.auto_awesome_outlined,
                              color: AppColors.yellowDark,
                            ),
                            title: const Text('Asistente IA Gemini'),
                            subtitle: const Text(
                              'Cotizaciones, oficios y redacción inteligente',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.push(AppRoutes.aiAssistant),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            secondary: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                            ),
                            title: const Text('Modo oscuro'),
                            subtitle: const Text(
                              'Alterna entre superficie clara y grafito oscuro',
                            ),
                            activeThumbColor: AppColors.yellow,
                            value: themeProvider.isDarkMode,
                            onChanged: (v) => themeProvider.toggleDarkMode(v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileFieldRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final pending = value == 'Pendiente';
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.grayMuted),
        const SizedBox(width: 12),
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: pending
                  ? AppColors.grayMuted
                  : Theme.of(context).colorScheme.onSurface,
              fontStyle: pending ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
