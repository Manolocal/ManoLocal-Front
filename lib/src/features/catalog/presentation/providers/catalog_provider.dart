import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/catalog_models.dart';
import '../../domain/repositories/catalog_repository.dart';

/// Provider para la gestión del catálogo de fotografías de trabajos del especialista.
class CatalogProvider extends ChangeNotifier {
  final CatalogRepository catalogRepository;

  List<CatalogImageModel> _images = const [];
  CatalogQuotaModel _quota =
      const CatalogQuotaModel(active: 0, limit: 10, remaining: 10);
  bool _isLoading = false;
  bool _isUploading = false;
  String? _deletingId;
  String? _errorMessage;

  CatalogProvider({required this.catalogRepository});

  List<CatalogImageModel> get images => _images;
  CatalogQuotaModel get quota => _quota;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get deletingId => _deletingId;
  String? get errorMessage => _errorMessage;
  bool get canUploadMore => _quota.remaining > 0;

  Future<bool> loadMyCatalog() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await catalogRepository.getMyImages();
      _images = result.images;
      _quota = result.quota;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadImage({
    required String filePath,
    required String title,
    String? description,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await catalogRepository.uploadImage(
        filePath: filePath,
        title: title,
        description: description,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      _images = [result.image, ..._images];
      _quota = result.quota;
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteImage(String imageId) async {
    _deletingId = imageId;
    _errorMessage = null;
    notifyListeners();

    try {
      await catalogRepository.deleteImage(imageId);
      _images = _images.where((img) => img.id != imageId).toList();
      final active = _images.length;
      _quota = CatalogQuotaModel(
        active: active,
        limit: _quota.limit,
        remaining: (_quota.limit - active).clamp(0, _quota.limit),
      );
      _deletingId = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _deletingId = null;
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _images = const [];
    _quota = const CatalogQuotaModel(active: 0, limit: 10, remaining: 10);
    _errorMessage = null;
    _isLoading = false;
    _isUploading = false;
    _deletingId = null;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException && error.error is AppException) {
      return (error.error as AppException).message;
    }
    if (error is AppException) {
      return error.message;
    }
    return error.toString();
  }
}
