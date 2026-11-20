import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/navigation_keys.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badges.dart';
import '../../../users/presentation/providers/profile_provider.dart';
import '../providers/kyc_provider.dart';

/// Flujo guiado de Verificación de Identidad KYC (`POST /kyc/documents`: INE + Selfie).
class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _picker = ImagePicker();

  Future<void> _pickDocument({
    required bool isIne,
    required ImageSource source,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        preferredCameraDevice:
            isIne ? CameraDevice.rear : CameraDevice.front,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final selected = SelectedKycFile(
        path: picked.path,
        name: picked.name,
        bytes: bytes,
      );
      final kyc = context.read<KycProvider>();
      if (isIne) {
        kyc.setIneFile(selected);
      } else {
        kyc.setSelfieFile(selected);
      }
    } catch (e) {
      GlobalNotifier.showErrorSnackBar(
        'No se pudo capturar la imagen: $e',
      );
    }
  }

  Future<void> _submit() async {
    final kyc = context.read<KycProvider>();
    final result = await kyc.submitDocuments();
    if (result != null && mounted) {
      await context.read<ProfileProvider>().loadProfile();
      GlobalNotifier.showSuccessSnackBar(
        'Documentos KYC enviados correctamente. Estado: ${result.userStatus?.label ?? 'Actualizado'}.',
      );
    } else if (mounted && kyc.errorMessage != null) {
      GlobalNotifier.showErrorSnackBar(kyc.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyc = context.watch<KycProvider>();
    final profile = context.watch<ProfileProvider>();
    final userMe = profile.userMe;
    final status = userMe?.status ?? UserStatus.inactivo;
    final existingIneUrl = userMe?.profile?.ineUrl;
    final existingSelfieUrl = userMe?.profile?.selfieUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Identidad (KYC)'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_user_rounded,
                                  color: AppColors.yellow,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Confianza bilateral ManoLocal',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            UserStatusBadge(status: status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tus documentos se resguardan de forma privada y nunca se exponen en perfiles públicos. Solo se muestran insignias oficiales de identidad validada.',
                          style: TextStyle(
                            color: AppColors.silver,
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (kyc.errorMessage != null) ...[
                    AppStatusBanner.error(kyc.errorMessage!),
                    const SizedBox(height: 14),
                  ],
                  if (status == UserStatus.activo) ...[
                    AppStatusBanner.success(
                      'Tu identidad ya fue validada oficialmente. Puedes actualizar tus fotos si lo necesitas.',
                    ),
                    const SizedBox(height: 16),
                  ] else if (status == UserStatus.pendienteValidacion) ...[
                    AppStatusBanner.info(
                      'Tus documentos KYC fueron recibidos y tu cuenta está en cola de validación.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  _KycCaptureCard(
                    stepNumber: 'Paso 1',
                    title: 'Credencial oficial (INE)',
                    tips:
                        'Colócala sobre una superficie iluminada, sin reflejos y con texto legible.',
                    icon: Icons.credit_card_rounded,
                    selectedFile: kyc.ineFile,
                    existingUrl: existingIneUrl,
                    onCamera: () => _pickDocument(
                      isIne: true,
                      source: ImageSource.camera,
                    ),
                    onGallery: () => _pickDocument(
                      isIne: true,
                      source: ImageSource.gallery,
                    ),
                    onClear: () => kyc.setIneFile(null),
                  ),
                  const SizedBox(height: 14),
                  _KycCaptureCard(
                    stepNumber: 'Paso 2',
                    title: 'Selfie con rostro descubierto',
                    tips:
                        'Mira de frente a la cámara en un lugar iluminado, sin lentes oscuros ni gorra.',
                    icon: Icons.face_retouching_natural_rounded,
                    selectedFile: kyc.selfieFile,
                    existingUrl: existingSelfieUrl,
                    onCamera: () => _pickDocument(
                      isIne: false,
                      source: ImageSource.camera,
                    ),
                    onGallery: () => _pickDocument(
                      isIne: false,
                      source: ImageSource.gallery,
                    ),
                    onClear: () => kyc.setSelfieFile(null),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: CheckboxListTile(
                      value: kyc.acceptedPrivacy,
                      onChanged: kyc.isUploading
                          ? null
                          : (v) => kyc.setAcceptedPrivacy(v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.yellow,
                      checkColor: AppColors.gray,
                      title: const Text(
                        'Aviso de Privacidad y Deslinde de Responsabilidad',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Autorizo el tratamiento seguro de mi INE y selfie exclusivamente para validar mi identidad en ManoLocal.',
                          style: TextStyle(fontSize: 12, height: 1.35),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: kyc.canSubmit ? _submit : null,
                    icon: kyc.isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gray,
                            ),
                          )
                        : const Icon(Icons.shield_outlined),
                    label: Text(
                      kyc.isUploading
                          ? 'Subiendo documentos de forma segura...'
                          : 'Enviar verificación KYC',
                    ),
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

class _KycCaptureCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String tips;
  final IconData icon;
  final SelectedKycFile? selectedFile;
  final String? existingUrl;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onClear;

  const _KycCaptureCard({
    required this.stepNumber,
    required this.title,
    required this.tips,
    required this.icon,
    required this.selectedFile,
    required this.existingUrl,
    required this.onCamera,
    required this.onGallery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocal = selectedFile?.bytes != null;
    final hasExisting = !hasLocal && existingUrl != null && existingUrl!.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.yellowSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: AppColors.gray,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleSmall),
                ),
                if (hasLocal || hasExisting)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(tips, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.silverLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.silver),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasLocal
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(selectedFile!.bytes!, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.gray,
                              foregroundColor: AppColors.yellow,
                            ),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: onClear,
                          ),
                        ),
                      ],
                    )
                  : hasExisting
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              existingUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: Text(
                                  'Documento ya cargado en el servidor',
                                  style: TextStyle(color: AppColors.grayMuted),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gray.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Cargado previamente',
                                  style: TextStyle(
                                    color: AppColors.yellow,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Icon(
                            icon,
                            size: 46,
                            color: AppColors.grayMuted,
                          ),
                        ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCamera,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text(
                      'Cámara',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGallery,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text(
                      'Galería',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
