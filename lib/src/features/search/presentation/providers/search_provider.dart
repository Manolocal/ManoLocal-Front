import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../catalog/domain/models/catalog_models.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';
import '../../domain/models/search_models.dart';
import '../../domain/repositories/search_repository.dart';

/// Provider para búsqueda geolocalizada por oficio y CP municipal (SEPOMEX / Copomex).
class SearchProvider extends ChangeNotifier {
  final SearchRepository searchRepository;
  final CatalogRepository catalogRepository;

  List<SpecialistSearchItemModel> _specialists = const [];
  GeoFilterModel? _geoFilter;
  PaginationMeta? _pagination;
  GeoInfoModel? _previewGeoInfo;

  String _lastSkill = '';
  String? _lastPostalCode;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLookingUpGeo = false;
  String? _errorMessage;

  // Portafolio público de un especialista seleccionado
  SpecialistCatalogModel? _selectedPortfolio;
  bool _isLoadingPortfolio = false;
  String? _portfolioError;

  SearchProvider({
    required this.searchRepository,
    required this.catalogRepository,
  });

  List<SpecialistSearchItemModel> get specialists => _specialists;
  GeoFilterModel? get geoFilter => _geoFilter;
  PaginationMeta? get pagination => _pagination;
  GeoInfoModel? get previewGeoInfo => _previewGeoInfo;

  String get lastSkill => _lastSkill;
  String? get lastPostalCode => _lastPostalCode;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLookingUpGeo => _isLookingUpGeo;
  String? get errorMessage => _errorMessage;
  bool get hasSearched => _lastSkill.isNotEmpty;
  bool get hasMore => _pagination?.hasNext ?? false;

  SpecialistCatalogModel? get selectedPortfolio => _selectedPortfolio;
  bool get isLoadingPortfolio => _isLoadingPortfolio;
  String? get portfolioError => _portfolioError;

  Future<bool> search({
    required String skill,
    String? postalCode,
    int limit = 10,
  }) async {
    final cleanSkill = skill.trim();
    if (cleanSkill.isEmpty) {
      _errorMessage = 'Ingresa el oficio o servicio que necesitas buscar.';
      notifyListeners();
      return false;
    }

    _lastSkill = cleanSkill;
    _lastPostalCode = postalCode?.trim().isNotEmpty == true
        ? postalCode!.trim()
        : null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await searchRepository.searchSpecialists(
        skill: cleanSkill,
        postalCode: _lastPostalCode,
        page: 1,
        limit: limit,
      );
      _specialists = result.specialists;
      _geoFilter = result.geoFilter;
      _pagination = result.pagination;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _specialists = const [];
      _geoFilter = null;
      _pagination = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || _lastSkill.isEmpty) return;

    final nextPage = (_pagination?.page ?? 1) + 1;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await searchRepository.searchSpecialists(
        skill: _lastSkill,
        postalCode: _lastPostalCode,
        page: nextPage,
        limit: _pagination?.limit ?? 10,
      );
      _specialists = [..._specialists, ...result.specialists];
      _geoFilter = result.geoFilter;
      _pagination = result.pagination;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<GeoInfoModel?> lookupGeoInfo(String postalCode) async {
    final clean = postalCode.trim();
    if (clean.length != 5) {
      _previewGeoInfo = null;
      notifyListeners();
      return null;
    }

    _isLookingUpGeo = true;
    notifyListeners();

    try {
      _previewGeoInfo = await searchRepository.getGeoInfo(clean);
      _isLookingUpGeo = false;
      notifyListeners();
      return _previewGeoInfo;
    } catch (_) {
      _previewGeoInfo = null;
      _isLookingUpGeo = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadSpecialistPortfolio(String specialistId) async {
    _isLoadingPortfolio = true;
    _portfolioError = null;
    _selectedPortfolio = null;
    notifyListeners();

    try {
      _selectedPortfolio =
          await catalogRepository.getSpecialistImages(specialistId);
    } catch (e) {
      _portfolioError = _extractErrorMessage(e);
    } finally {
      _isLoadingPortfolio = false;
      notifyListeners();
    }
  }

  void clear() {
    _specialists = const [];
    _geoFilter = null;
    _pagination = null;
    _previewGeoInfo = null;
    _lastSkill = '';
    _lastPostalCode = null;
    _errorMessage = null;
    _selectedPortfolio = null;
    _portfolioError = null;
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
