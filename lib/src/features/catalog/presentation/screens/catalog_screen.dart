import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/navigation_keys.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/models/catalog_models.dart';
import '../providers/catalog_provider.dart';

/// Catálogo de Trabajos del Especialista (`/catalog/me`, límite de 10 fotos activas).
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CatalogProvider>().loadMyCatalog();
    });
  }

  Future<void> _openUploadSheet() async {
    final catalog = context.read<CatalogProvider>();
    if (!catalog.canUploadMore) {
      GlobalNotifier.showWarningSnackBar(
        'Alcanzaste el límite de ${catalog.quota.limit} fotos activas. Elimina una para subir otra.',
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    XFile? pickedFile;
    Uint8List? previewBytes;

    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> pickFrom(ImageSource source) async {
            try {
              final img = await _picker.pickImage(
                source: source,
                maxWidth: 1600,
                imageQuality: 85,
              );
              if (img == null) return;
              final bytes = await img.readAsBytes();
              setModalState(() {
                pickedFile = img;
                previewBytes = bytes;
              });
            } catch (e) {
              GlobalNotifier.showErrorSnackBar(
                'No se pudo seleccionar la imagen: $e',
              );
            }
          }

          return Padding(
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
                      'Agregar trabajo al catálogo',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Muestra evidencia real de tu calidad. Formatos: JPG, PNG o WEBP (máx. 5 MB).',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.silverLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.silver),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: previewBytes != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(previewBytes!, fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.gray,
                                      foregroundColor: AppColors.yellow,
                                    ),
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () => setModalState(() {
                                      pickedFile = null;
                                      previewBytes = null;
                                    }),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: AppColors.grayMuted,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          pickFrom(ImageSource.camera),
                                      icon: const Icon(
                                        Icons.photo_camera_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Cámara'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          pickFrom(ImageSource.gallery),
                                      icon: const Icon(
                                        Icons.photo_library_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Galería'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: titleCtrl,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Título del trabajo *',
                        hintText: 'Ej. Instalación de regadera tipo lluvia',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) {
                        final text = v?.trim() ?? '';
                        if (text.length < 3) {
                          return 'El título debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        labelText: 'Descripción y materiales (opcional)',
                        hintText:
                            'Tubería de cobre, sellado antihongos y prueba de presión.',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        if (pickedFile == null || previewBytes == null) {
                          GlobalNotifier.showWarningSnackBar(
                            'Selecciona una fotografía primero.',
                          );
                          return;
                        }
                        if (!formKey.currentState!.validate()) return;
                        Navigator.of(ctx).pop({
                          'path': pickedFile!.path,
                          'name': pickedFile!.name,
                          'bytes': previewBytes,
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                        });
                      },
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Publicar en mi catálogo'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (payload == null || !mounted) return;
    final ok = await context.read<CatalogProvider>().uploadImage(
          filePath: payload['path'] as String,
          fileName: payload['name'] as String,
          fileBytes: payload['bytes'] as Uint8List,
          title: payload['title'] as String,
          description: (payload['description'] as String).isEmpty
              ? null
              : payload['description'] as String,
        );

    if (ok && mounted) {
      GlobalNotifier.showSuccessSnackBar(
        'Fotografía publicada en tu catálogo exitosamente.',
      );
    } else if (mounted) {
      final err = context.read<CatalogProvider>().errorMessage;
      if (err != null) GlobalNotifier.showErrorSnackBar(err);
    }
  }

  Future<void> _confirmDelete(CatalogImageModel image) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar fotografía'),
        content: Text(
          '¿Deseas eliminar "${image.title}" de tu catálogo? Se liberará un espacio en tu cuota inmediatamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    final ok = await context.read<CatalogProvider>().deleteImage(image.id);
    if (ok && mounted) {
      GlobalNotifier.showSuccessSnackBar('Fotografía eliminada del catálogo.');
    }
  }

  void _openPreview(CatalogImageModel image) {
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
                  Text(image.title, style: Theme.of(ctx).textTheme.titleMedium),
                  if (image.description != null &&
                      image.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(image.description!),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Publicada el ${AppFormatters.dateTime(image.createdAt)}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _confirmDelete(image);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Eliminar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
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
    final catalog = context.watch<CatalogProvider>();
    final quota = catalog.quota;
    final ratio = quota.limit > 0
        ? (quota.active / quota.limit).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Catálogo de Trabajos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (catalog.isUploading || !catalog.canUploadMore)
            ? null
            : _openUploadSheet,
        icon: catalog.isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gray,
                ),
              )
            : const Icon(Icons.add_a_photo_rounded),
        label: Text(
          catalog.isUploading
              ? 'Subiendo...'
              : (catalog.canUploadMore ? 'Subir foto' : 'Límite 10/10'),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.gray,
        backgroundColor: AppColors.yellow,
        onRefresh: () => catalog.loadMyCatalog(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: AppColors.gray,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.photo_library_rounded,
                                  color: AppColors.yellow,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Cuota de portafolio',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${quota.active} / ${quota.limit} fotos',
                                  style: const TextStyle(
                                    color: AppColors.yellow,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 7,
                                backgroundColor: AppColors.graySurface,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.yellow,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              quota.remaining > 0
                                  ? 'Tienes ${quota.remaining} espacios disponibles para mostrar tus mejores trabajos.'
                                  : 'Has llenado tu galería de 10 fotos. Elimina alguna para publicar nuevas evidencias.',
                              style: const TextStyle(
                                color: AppColors.silver,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (catalog.isLoading && catalog.images.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (catalog.errorMessage != null &&
                        catalog.images.isEmpty)
                      ErrorStateView(
                        message: catalog.errorMessage!,
                        onRetry: () => catalog.loadMyCatalog(),
                      )
                    else if (catalog.images.isEmpty)
                      EmptyStateView(
                        icon: Icons.collections_outlined,
                        title: 'Tu catálogo está vacío',
                        description:
                            'Sube fotos de trabajos anteriores para generar más confianza y recibir más solicitudes de clientes en tu zona.',
                        actionLabel: 'Subir primera foto',
                        onAction: _openUploadSheet,
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: catalog.images.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 236 *
                              MediaQuery.textScalerOf(context)
                                  .scale(1)
                                  .clamp(1.0, 1.35),
                        ),
                        itemBuilder: (context, index) {
                          final item = catalog.images[index];
                          final deleting = catalog.deletingId == item.id;
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _openPreview(item),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            color: AppColors.silverLight,
                                            child: const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: AppColors.grayMuted,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Material(
                                            color: AppColors.gray
                                                .withValues(alpha: 0.85),
                                            shape: const CircleBorder(),
                                            child: IconButton(
                                              iconSize: 18,
                                              constraints: const BoxConstraints(
                                                minWidth: 34,
                                                minHeight: 34,
                                              ),
                                              padding: EdgeInsets.zero,
                                              tooltip: 'Eliminar',
                                              onPressed: deleting
                                                  ? null
                                                  : () => _confirmDelete(item),
                                              icon: deleting
                                                  ? const SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: AppColors.yellow,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      color: AppColors.white,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        if (item.description != null &&
                                            item.description!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.description!,
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
      ),
    );
  }
}
