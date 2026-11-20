import 'dart:typed_data';
import 'package:dio/dio.dart';

/// Construye objetos `MultipartFile` con MIME type y extensión válidos para
/// los filtros de Multer y `FileValidationPipe` de ManoLocal-Back.
class FileUploadHelper {
  FileUploadHelper._();

  static Future<MultipartFile> fromPathOrBytes({
    String? filePath,
    Uint8List? bytes,
    String? fileName,
    String defaultName = 'upload.jpg',
  }) async {
    final resolvedName = _ensureExtension(
      fileName ?? _extractBaseName(filePath) ?? defaultName,
      fallback: defaultName,
    );
    final mediaType = _inferMediaType(resolvedName);

    if (bytes != null && bytes.isNotEmpty) {
      return MultipartFile.fromBytes(
        bytes,
        filename: resolvedName,
        contentType: mediaType,
      );
    }

    if (filePath != null && filePath.isNotEmpty) {
      return MultipartFile.fromFile(
        filePath,
        filename: resolvedName,
        contentType: mediaType,
      );
    }

    throw ArgumentError('Debes proporcionar un archivo o sus bytes para subirlo.');
  }

  static String? _extractBaseName(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final normalized = path.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    return idx >= 0 ? normalized.substring(idx + 1) : normalized;
  }

  static String _ensureExtension(String name, {required String fallback}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return fallback;
    final lower = trimmed.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.pdf')) {
      return trimmed;
    }
    return '$trimmed.jpg';
  }

  static DioMediaType _inferMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return DioMediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return DioMediaType('image', 'webp');
    }
    if (lower.endsWith('.pdf')) {
      return DioMediaType('application', 'pdf');
    }
    return DioMediaType('image', 'jpeg');
  }
}
