import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badges.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../jobs/domain/models/job_models.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../../../users/presentation/providers/profile_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

/// Pantalla de Inicio (Dashboard) profesional adaptada al rol del usuario
/// (Empleador, Especialista o Administrador).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const List<_QuickCategory> _categories = [
    _QuickCategory('Plomería', Icons.plumbing_rounded),
    _QuickCategory('Electricidad', Icons.electrical_services_rounded),
    _QuickCategory('Carpintería', Icons.carpenter_rounded),
    _QuickCategory('Pintura', Icons.format_paint_rounded),
    _QuickCategory('Herrería', Icons.hardware_rounded),
    _QuickCategory('Albañilería', Icons.foundation_rounded),
    _QuickCategory('Clima / A/C', Icons.ac_unit_rounded),
    _QuickCategory('Jardinería', Icons.yard_rounded),
  ];

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
    }
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final role = auth.user?.role ?? UserRole.empleador;
    final profileProvider = context.read<ProfileProvider>();
    final jobsProvider = context.read<JobsProvider>();
    final chatProvider = context.read<ChatProvider>();

    final tasks = <Future<dynamic>>[
      profileProvider.loadProfile(),
      jobsProvider.loadMyJobs(),
      chatProvider.loadRooms(),
    ];

    if (role == UserRole.especialista) {
      tasks.add(context.read<WalletProvider>().loadWallet());
      tasks.add(context.read<CatalogProvider>().loadMyCatalog());
    } else if (role == UserRole.admin) {
      tasks.add(context.read<WalletProvider>().loadWallet());
    }

    await Future.wait(tasks);
  }

  void _quickSearchCategory(String category) {
    final searchProvider = context.read<SearchProvider>();
    final cp = context.read<ProfileProvider>().userMe?.profile?.postalCode;
    unawaited(searchProvider.search(skill: category, postalCode: cp));
    context.go(AppRoutes.search);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final jobs = context.watch<JobsProvider>();
    final chat = context.watch<ChatProvider>();
    final wallet = context.watch<WalletProvider>();
    final catalog = context.watch<CatalogProvider>();

    final userMe = profile.userMe;
    final role = userMe?.role ?? auth.user?.role ?? UserRole.empleador;
    final status = userMe?.status ?? auth.user?.status ?? UserStatus.inactivo;
    final displayName =
        userMe?.displayName ?? auth.user?.displayName ?? 'Usuario';
    final postalCode = userMe?.profile?.postalCode;
    final activeJobs = jobs.myJobs
        .where(
          (j) =>
              j.status == JobStatus.pending || j.status == JobStatus.confirmed,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(
          size: 32,
          showWordmark: true,
          lightWordmark: true,
        ),
        actions: [
          IconButton(
            tooltip: 'Asistente Gemini AI',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () => context.push(AppRoutes.aiAssistant),
          ),
          IconButton(
            tooltip: 'Mi Perfil',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.go(AppRoutes.profile),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gray,
        backgroundColor: AppColors.yellow,
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroWelcomeCard(
                      displayName: displayName,
                      role: role,
                      status: status,
                      postalCode: postalCode,
                    ),
                    const SizedBox(height: 16),
                    if (status != UserStatus.activo) ...[
                      _OnboardingChecklistCard(
                        role: role,
                        status: status,
                        progress: profile.completionProgress,
                        personalDone: profile.isPersonalDataComplete,
                        kycDone: profile.isKycComplete,
                        knowledgeDone: profile.isKnowledgeComplete,
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (role == UserRole.especialista) ...[
                      _SpecialistMetricsRow(
                        walletBalance: wallet.wallet?.balanceDisponible ?? 0,
                        frozenBalance: wallet.wallet?.balanceCongelado ?? 0,
                        catalogActive: catalog.quota.active,
                        catalogLimit: catalog.quota.limit,
                        activeJobsCount: activeJobs.length,
                      ),
                      const SizedBox(height: 22),
                    ] else ...[
                      _EmployerQuickSearchCard(
                        postalCode: postalCode,
                        onTapSearch: () => context.go(AppRoutes.search),
                      ),
                      const SizedBox(height: 22),
                      SectionHeader(
                        title: 'Oficios populares en tu zona',
                        subtitle: 'Toca una especialidad para buscar cerca de ti',
                        actionLabel: 'Buscar',
                        onAction: () => context.go(AppRoutes.search),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _categories.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 196,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 102 *
                              MediaQuery.textScalerOf(context)
                                  .scale(1)
                                  .clamp(1.0, 1.4),
                        ),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return _CategoryCard(
                            category: cat,
                            onTap: () => _quickSearchCategory(cat.name),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    SectionHeader(
                      title: 'Acuerdos de trabajo activos',
                      subtitle: activeJobs.isEmpty
                          ? 'Formaliza servicios desde tus conversaciones'
                          : '${activeJobs.length} en curso',
                      actionLabel: 'Ver todos',
                      onAction: () => context.go(AppRoutes.jobs),
                    ),
                    const SizedBox(height: 10),
                    if (jobs.isLoading && activeJobs.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else if (activeJobs.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.yellowSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.handshake_outlined,
                                  color: AppColors.gray,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sin acuerdos activos aún',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      role == UserRole.especialista
                                          ? 'Mantén tu perfil, catálogo y saldo al día para confirmar trabajos desde el chat.'
                                          : 'Encuentra un especialista verificado y acuerda los detalles en el chat privado.',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...activeJobs.take(3).map(
                            (job) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CompactJobTile(
                                job: job,
                                onTap: () => context
                                    .push(AppRoutes.chatRoomPath(job.roomId)),
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: 'Conversaciones recientes',
                      subtitle: chat.rooms.isEmpty
                          ? 'Mensajería directa 1 a 1 en tiempo real'
                          : '${chat.rooms.length} salas activas',
                      actionLabel: 'Abrir chat',
                      onAction: () => context.go(AppRoutes.chat),
                    ),
                    const SizedBox(height: 10),
                    if (chat.rooms.isEmpty)
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.silverLight,
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.gray,
                            ),
                          ),
                          title: const Text(
                            'Bandeja de mensajes vacía',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'Aquí aparecerán tus conversaciones y cotizaciones.',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.go(AppRoutes.chat),
                        ),
                      )
                    else
                      Card(
                        child: Column(
                          children: [
                            for (var i = 0;
                                i < chat.rooms.take(3).length;
                                i++) ...[
                              if (i > 0) const Divider(height: 1),
                              Builder(
                                builder: (context) {
                                  final room = chat.rooms[i];
                                  final name = room.counterpart?.displayName ??
                                      'Conversación';
                                  return ListTile(
                                    leading: UserAvatar(
                                      initials: AppFormatters.initials(name),
                                      radius: 20,
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      room.lastMessage?.content ??
                                          'Sin mensajes todavía',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      AppFormatters.shortTime(
                                        room.lastMessage?.createdAt ??
                                            room.updatedAt,
                                      ),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    onTap: () => context.push(
                                      AppRoutes.chatRoomPath(room.id),
                                      extra: room,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    _GeminiAssistantPromoCard(
                      role: role,
                      onOpen: () => context.push(AppRoutes.aiAssistant),
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

class _HeroWelcomeCard extends StatelessWidget {
  final String displayName;
  final UserRole role;
  final UserStatus status;
  final String? postalCode;

  const _HeroWelcomeCard({
    required this.displayName,
    required this.role,
    required this.status,
    this.postalCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.yellow.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                initials: AppFormatters.initials(displayName),
                radius: 24,
                highlighted: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $displayName',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.yellow,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            postalCode != null && postalCode!.isNotEmpty
                                ? 'Zona registrada: CP $postalCode'
                                : 'Agrega tu CP en tu perfil',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.silver,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RoleBadge(role: role),
              UserStatusBadge(status: status),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingChecklistCard extends StatelessWidget {
  final UserRole role;
  final UserStatus status;
  final double progress;
  final bool personalDone;
  final bool kycDone;
  final bool knowledgeDone;

  const _OnboardingChecklistCard({
    required this.role,
    required this.status,
    required this.progress,
    required this.personalDone,
    required this.kycDone,
    required this.knowledgeDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (progress * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.yellowDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status == UserStatus.pendienteValidacion
                        ? 'Documentación enviada · En revisión'
                        : 'Completa tu verificación ($pct%)',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.05, 1.0),
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 14),
            _ChecklistRow(
              label: 'Datos personales y Código Postal',
              done: personalDone,
              actionLabel: 'Completar',
              onTap: () => context.go(AppRoutes.profile),
            ),
            const SizedBox(height: 8),
            _ChecklistRow(
              label: 'Verificación KYC (INE + Selfie)',
              done: kycDone,
              actionLabel: 'Subir KYC',
              onTap: () => context.push(AppRoutes.kyc),
            ),
            if (role == UserRole.especialista) ...[
              const SizedBox(height: 8),
              _ChecklistRow(
                label: 'Registrar al menos un oficio',
                done: knowledgeDone,
                actionLabel: 'Agregar',
                onTap: () => context.go(AppRoutes.profile),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;
  final bool done;
  final String actionLabel;
  final VoidCallback onTap;

  const _ChecklistRow({
    required this.label,
    required this.done,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 19,
          color: done ? AppColors.success : AppColors.grayMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: done ? FontWeight.w500 : FontWeight.w600,
              decoration: done ? TextDecoration.lineThrough : null,
              color: done
                  ? AppColors.grayMuted
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (!done)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel),
          ),
      ],
    );
  }
}

class _SpecialistMetricsRow extends StatelessWidget {
  final double walletBalance;
  final double frozenBalance;
  final int catalogActive;
  final int catalogLimit;
  final int activeJobsCount;

  const _SpecialistMetricsRow({
    required this.walletBalance,
    required this.frozenBalance,
    required this.catalogActive,
    required this.catalogLimit,
    required this.activeJobsCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _MetricCard(
            title: 'Saldo disponible',
            value: AppFormatters.currency(walletBalance, withSuffix: false),
            subtitle:
                'Congelado: ${AppFormatters.currency(frozenBalance, withSuffix: false)}',
            icon: Icons.account_balance_wallet_rounded,
            accentYellow: true,
            onTap: () => context.go(AppRoutes.wallet),
          ),
          _MetricCard(
            title: 'Mi Catálogo',
            value: '$catalogActive / $catalogLimit',
            subtitle: 'Fotos de trabajos activas',
            icon: Icons.photo_library_rounded,
            onTap: () => context.go(AppRoutes.catalog),
          ),
          _MetricCard(
            title: 'Trabajos activos',
            value: '$activeJobsCount',
            subtitle: 'Ver acuerdos y estados',
            icon: Icons.work_rounded,
            onTap: () => context.go(AppRoutes.jobs),
          ),
        ];

        if (constraints.maxWidth >= 680) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        return Column(
          children: [
            cards[0],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: cards[1]),
                const SizedBox(width: 10),
                Expanded(child: cards[2]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool accentYellow;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accentYellow = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: accentYellow ? AppColors.yellowSoft : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color:
                            accentYellow ? AppColors.gray : AppColors.grayMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    icon,
                    size: 20,
                    color: accentYellow ? AppColors.gray : AppColors.yellowDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: accentYellow ? AppColors.gray : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: accentYellow ? AppColors.grayMuted : AppColors.grayMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployerQuickSearchCard extends StatelessWidget {
  final String? postalCode;
  final VoidCallback onTapSearch;

  const _EmployerQuickSearchCard({
    this.postalCode,
    required this.onTapSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: InkWell(
        onTap: onTapSearch,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Qué oficio necesitas hoy?',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      postalCode != null && postalCode!.isNotEmpty
                          ? 'Buscar especialistas en tu municipio (CP $postalCode)'
                          : 'Filtra por oficio y código postal SEPOMEX',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.silver : AppColors.grayMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCategory {
  final String name;
  final IconData icon;
  const _QuickCategory(this.name, this.icon);
}

class _CategoryCard extends StatelessWidget {
  final _QuickCategory category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.graySurface : AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category.icon,
                  size: 20,
                  color: isDark ? AppColors.yellow : AppColors.gray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactJobTile extends StatelessWidget {
  final JobAgreementModel job;
  final VoidCallback onTap;

  const _CompactJobTile({
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Row(
          children: [
            Expanded(
              child: Text(
                job.title?.isNotEmpty == true
                    ? job.title!
                    : 'Acuerdo de servicio',
                style: const TextStyle(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            JobStatusBadge(status: job.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            [
              if (job.agreedPrice != null)
                'Precio: ${AppFormatters.currency(job.agreedPrice!, withSuffix: false)}',
              'Cuota: ${AppFormatters.currency(job.feeAmount, withSuffix: false)}',
            ].join('  ·  '),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _GeminiAssistantPromoCard extends StatelessWidget {
  final UserRole role;
  final VoidCallback onOpen;

  const _GeminiAssistantPromoCard({
    required this.role,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final description = role == UserRole.especialista
        ? 'Redacta cotizaciones y descripciones profesionales para tu catálogo.'
        : 'Describe tu problema del hogar y te ayudamos a cotizar con el oficio ideal.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.graySurface),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          final actionButton = FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Abrir'),
          );

          final infoRow = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gray,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Asistente IA ManoLocal',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.silver,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 10),
                actionButton,
              ],
            ],
          );

          if (!isCompact) return infoRow;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              infoRow,
              const SizedBox(height: 12),
              actionButton,
            ],
          );
        },
      ),
    );
  }
}
