import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/navigation_keys.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badges.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../users/presentation/providers/profile_provider.dart';
import '../../domain/models/search_models.dart';
import '../providers/search_provider.dart';

/// Búsqueda geolocalizada de especialistas por oficio y municipio SEPOMEX / Copomex.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const List<String> _popularSkills = [
    'Plomero',
    'Electricista',
    'Carpintero',
    'Pintor',
    'Herrero',
    'Albañil',
    'Cerrajero',
    'Jardinero',
  ];

  final _skillController = TextEditingController();
  final _cpController = TextEditingController();
  bool _prefilled = false;
  String? _contactingSpecialistId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefilled) {
      _prefilled = true;
      final search = context.read<SearchProvider>();
      final profileCp =
          context.read<ProfileProvider>().userMe?.profile?.postalCode;
      if (search.lastSkill.isNotEmpty) {
        _skillController.text = search.lastSkill;
      }
      if (search.lastPostalCode != null && search.lastPostalCode!.isNotEmpty) {
        _cpController.text = search.lastPostalCode!;
      } else if (profileCp != null && profileCp.isNotEmpty) {
        _cpController.text = profileCp;
      }
    }
  }

  @override
  void dispose() {
    _skillController.dispose();
    _cpController.dispose();
    super.dispose();
  }

  Future<void> _executeSearch({String? overrideSkill}) async {
    final skill = (overrideSkill ?? _skillController.text).trim();
    if (overrideSkill != null) {
      _skillController.text = overrideSkill;
    }
    if (skill.isEmpty) {
      GlobalNotifier.showWarningSnackBar(
        'Escribe el oficio o habilidad que estás buscando.',
      );
      return;
    }

    final cp = _cpController.text.trim();
    if (cp.isNotEmpty && AppValidators.postalCodeMx(cp) != null) {
      GlobalNotifier.showWarningSnackBar(
        'El Código Postal debe tener exactamente 5 dígitos numéricos.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    await context.read<SearchProvider>().search(
          skill: skill,
          postalCode: cp.isEmpty ? null : cp,
        );
  }

  Future<void> _contactSpecialist(SpecialistSearchItemModel specialist) async {
    setState(() => _contactingSpecialistId = specialist.id);
    try {
      final room = await context.read<ChatProvider>().openOrCreateRoom(
            specialistId: specialist.id,
          );
      if (room != null && mounted) {
        context.push(AppRoutes.chatRoomPath(room.id), extra: room);
      }
    } finally {
      if (mounted) {
        setState(() => _contactingSpecialistId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Especialistas'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _skillController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _executeSearch(),
                            decoration: InputDecoration(
                              labelText: '¿Qué oficio o servicio buscas?',
                              hintText: 'Ej. Plomero, Electricista, Carpintero',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _skillController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: () {
                                        _skillController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _cpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 5,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) {
                                    if (value.trim().length == 5) {
                                      context
                                          .read<SearchProvider>()
                                          .lookupGeoInfo(value.trim());
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Código Postal',
                                    hintText: 'Ej. 01000',
                                    counterText: '',
                                    prefixIcon:
                                        Icon(Icons.location_on_outlined),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: search.isLoading
                                      ? null
                                      : () => _executeSearch(),
                                  icon: search.isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.gray,
                                          ),
                                        )
                                      : const Icon(Icons.travel_explore_rounded),
                                  label: const Text('Buscar'),
                                ),
                              ),
                            ],
                          ),
                          if (search.isLookingUpGeo) ...[
                            const SizedBox(height: 8),
                            const LinearProgressIndicator(minHeight: 2),
                          ] else if (search.previewGeoInfo != null &&
                              search.previewGeoInfo!.municipio.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.map_outlined,
                                  size: 16,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Municipio detectado: ${search.previewGeoInfo!.municipio} (${search.previewGeoInfo!.postalCodes.length} CPs en cobertura)',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _popularSkills
                                .map(
                                  (skill) => ActionChip(
                                    label: Text(skill),
                                    onPressed: () =>
                                        _executeSearch(overrideSkill: skill),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (search.geoFilter != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_city_rounded,
                            color: AppColors.yellow,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${search.geoFilter!.municipio} · CP ${search.geoFilter!.searchedPostalCode} (${search.geoFilter!.totalPostalCodesInMunicipality} CPs municipales)',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${search.pagination?.total ?? search.specialists.length}',
                              style: const TextStyle(
                                color: AppColors.gray,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (search.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (search.errorMessage != null)
                    ErrorStateView(
                      message: search.errorMessage!,
                      onRetry: _executeSearch,
                    )
                  else if (!search.hasSearched)
                    EmptyStateView(
                      icon: Icons.location_searching_rounded,
                      title: 'Encuentra talento confiable en tu municipio',
                      description:
                          'Busca por oficio y delimitamos los resultados automáticamente con el catálogo oficial de códigos postales SEPOMEX.',
                      actionLabel: 'Buscar Plomeros',
                      onAction: () => _executeSearch(overrideSkill: 'Plomero'),
                    )
                  else if (search.specialists.isEmpty)
                    EmptyStateView(
                      icon: Icons.person_search_rounded,
                      title: 'Sin especialistas en esta búsqueda',
                      description:
                          'No encontramos especialistas verificados para "${search.lastSkill}" en este municipio. Prueba con otro término o código postal.',
                      actionLabel: 'Limpiar búsqueda',
                      onAction: () {
                        _skillController.clear();
                        search.clear();
                      },
                    )
                  else ...[
                    ...search.specialists.map(
                      (sp) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SpecialistCard(
                          specialist: sp,
                          isContacting: _contactingSpecialistId == sp.id,
                          onViewPortfolio: () => context.push(
                            AppRoutes.specialistDetailPath(sp.id),
                            extra: sp,
                          ),
                          onContact: () => _contactSpecialist(sp),
                        ),
                      ),
                    ),
                    if (search.hasMore) ...[
                      const SizedBox(height: 6),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: search.isLoadingMore
                              ? null
                              : () => search.loadMore(),
                          icon: search.isLoadingMore
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more_rounded),
                          label: Text(
                            search.isLoadingMore
                                ? 'Cargando más...'
                                : 'Cargar más especialistas',
                          ),
                        ),
                      ),
                    ],
                    if (search.pagination != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Mostrando ${search.specialists.length} de ${search.pagination!.total} especialistas',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  final SpecialistSearchItemModel specialist;
  final bool isContacting;
  final VoidCallback onViewPortfolio;
  final VoidCallback onContact;

  const _SpecialistCard({
    required this.specialist,
    required this.isContacting,
    required this.onViewPortfolio,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cp = specialist.profile?.postalCode;
    final hasValidatedCert = specialist.knowledges.any(
      (k) => k.verifications
          .any((v) => v.status == DocumentVerificationStatus.validated),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  initials: AppFormatters.initials(specialist.displayName),
                  radius: 24,
                  highlighted: specialist.status == UserStatus.activo,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialist.displayName,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          UserStatusBadge(status: specialist.status),
                          if (hasValidatedCert)
                            const AppPillBadge(
                              label: 'Certificado IA',
                              icon: Icons.workspace_premium_rounded,
                              backgroundColor: AppColors.yellowSoft,
                              foregroundColor: AppColors.gray,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (cp != null && cp.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.grayMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Cobertura en CP $cp',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (specialist.knowledges.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: specialist.knowledges.map((k) {
                  final verified = k.verifications.any(
                    (v) => v.status == DocumentVerificationStatus.validated,
                  );
                  return Chip(
                    avatar: Icon(
                      verified
                          ? Icons.verified_rounded
                          : Icons.build_circle_outlined,
                      size: 16,
                      color: verified ? AppColors.success : AppColors.gray,
                    ),
                    label: Text(k.name),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewPortfolio,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Portafolio'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isContacting ? null : onContact,
                    icon: isContacting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gray,
                            ),
                          )
                        : const Icon(Icons.chat_rounded, size: 18),
                    label: Text(isContacting ? 'Abriendo...' : 'Contactar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
