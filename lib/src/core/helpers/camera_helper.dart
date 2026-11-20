import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

export 'package:image_picker/image_picker.dart'
    show CameraDevice, ImageSource;

/// Imagen capturada o seleccionada localmente, lista para previsualización y envío multipart.
class CapturedImageFile {
  final String path;
  final String name;
  final Uint8List bytes;

  const CapturedImageFile({
    required this.path,
    required this.name,
    required this.bytes,
  });
}

/// Helper centralizado para captura desde cámara o selección desde galería
/// con compresión uniforme para KYC (INE/Selfie) y Catálogo de Trabajos.
class CameraHelper {
  final ImagePicker _picker;

  CameraHelper({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<CapturedImageFile?> pickImage({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    double maxWidth = 1600,
    int imageQuality = 85,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      preferredCameraDevice: preferredCameraDevice,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    return CapturedImageFile(
      path: picked.path,
      name: _resolveFileName(picked.name, picked.path),
      bytes: bytes,
    );
  }

  /// Captura de credencial oficial (INE) usando cámara trasera por defecto.
  Future<CapturedImageFile?> captureIne(ImageSource source) {
    return pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
    );
  }

  /// Captura de selfie biométrica usando cámara frontal por defecto.
  Future<CapturedImageFile?> captureSelfie(ImageSource source) {
    return pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
    );
  }

  /// Captura o selección de fotografía de evidencia para el catálogo del especialista.
  Future<CapturedImageFile?> captureCatalogPhoto(ImageSource source) {
    return pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
    );
  }

  static String _resolveFileName(String name, String path) {
    final candidate = name.trim().isNotEmpty ? name.trim() : path.trim();
    final normalized = candidate.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    final base = idx >= 0 ? normalized.substring(idx + 1) : normalized;
    return base.isEmpty ? 'image.jpg' : base;
  }
}
