import '../models/search_models.dart';

/// Contrato de repositorio para búsqueda geolocalizada de especialistas (SEPOMEX/Copomex).
abstract class SearchRepository {
  Future<SearchSpecialistsResultModel> searchSpecialists({
    required String skill,
    String? postalCode,
    int page = 1,
    int limit = 10,
  });

  Future<GeoInfoModel> getGeoInfo(String postalCode);
}
