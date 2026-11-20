import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badges.dart';
import '../../../catalog/domain/models/catalog_models.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../domain/models/search_models.dart';
import '../providers/search_provider.dart';

/// Perfil público y portafolio fotográfico de un especialista (`GET /catalog/specialist/:id`).
class SpecialistDetailScreen extends StatefulWidget {
  final String specialistId;
  final SpecialistSearchItemModel? preview;

  const SpecialistDetailScreen({
    super.key,
    required this.specialistId,
    this.preview,
  });

  @override
  State<SpecialistDetailScreen> createState() => _SpecialistDetailScreenState();
}

class _SpecialistDetailScreenState extends State<SpecialistDetailScreen> {
  bool _contacting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<SearchProvider>()
          .loadSpecialistPortfolio(widget.specialistId);
    });
  }

  Future<void> _startChat() async {
    setState(() => _contacting = true);
    try {
      final room = await context.read<ChatProvider>().openOrCreateRoom(
            specialistId: widget.specialistId,
          );
      if (room != null && mounted) {
        context.push(AppRoutes.chatRoomPath(room.id), extra: room);
      }
    } finally {
      if (mounted) setState(() => _contacting = false);
    }
  }

  void _openLightbox(CatalogImageModel image) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: InteractiveViewer(
                child: Image.network(
                  image.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 220,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.title,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  if (image.description != null &&
                      image.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      image.description!,
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cerrar'),
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

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final portfolio = search.selectedPortfolio;
    final preview = widget.preview;
    final name = preview?.displayName ??
        portfolio?.specialist.name ??
        'Especialista ManoLocal';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Especialista'),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _contacting ? null : _startChat,
                  icon: _contacting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gray,
                          ),
                        )
                      : const Icon(Icons.chat_bubble_rounded),
                  label: Text(
                    _contacting
                        ? 'Abriendo sala privada...'
                        : 'Iniciar conversación y cotizar',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          initials: AppFormatters.initials(name),
                          radius: 30,
                          highlighted: true,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  const RoleBadge(role: UserRole.especialista),
                                  UserStatusBadge(
                                    status:
                                        preview?.status ?? UserStatus.activo,
                                  ),
                                ],
                              ),
                              if (preview?.profile?.postalCode != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.yellow,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Zona de servicio: CP ${preview!.profile!.postalCode}',
                                      style: const TextStyle(
                                        color: AppColors.silver,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (preview != null && preview.knowledges.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const SectionHeader(
                      title: 'Oficios y certificaciones',
                      subtitle: 'Especialidades declaradas y respaldadas',
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: preview.knowledges.map((k) {
                            final validated = k.verifications.any(
                              (v) =>
                                  v.status ==
                                  DocumentVerificationStatus.validated,
                            );
                            return Chip(
                              avatar: Icon(
                                validated
                                    ? Icons.workspace_premium_rounded
                                    : Icons.handyman_outlined,
                                size: 17,
                                color: validated
                                    ? AppColors.success
                                    : AppColors.gray,
                              ),
                              label: Text(
                                validated ? '${k.name} · IA' : k.name,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: 'Portafolio de trabajos realizados',
                    subtitle: portfolio == null
                        ? 'Evidencia fotográfica del especialista'
                        : '${portfolio.images.length} fotografías publicadas',
                  ),
                  const SizedBox(height: 12),
                  if (search.isLoadingPortfolio)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (search.portfolioError != null)
                    ErrorStateView(
                      message: search.portfolioError!,
                      onRetry: () => search
                          .loadSpecialistPortfolio(widget.specialistId),
                    )
                  else if (portfolio == null || portfolio.images.isEmpty)
                    const EmptyStateView(
                      icon: Icons.photo_library_outlined,
                      title: 'Sin fotografías publicadas todavía',
                      description:
                          'Este especialista aún no ha subido trabajos a su galería pública. Puedes escribirle en el chat para pedir referencias.',
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: portfolio.images.length,
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 232 *
                            MediaQuery.textScalerOf(context)
                                .scale(1)
                                .clamp(1.0, 1.35),
                      ),
                      itemBuilder: (context, index) {
                        final image = portfolio.images[index];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _openLightbox(image),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Image.network(
                                    image.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: AppColors.silverLight,
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: AppColors.grayMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        image.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (image.description != null &&
                                          image.description!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          image.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
