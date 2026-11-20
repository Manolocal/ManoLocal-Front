import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/search_models.dart';

abstract class SearchRemoteDataSource {
  Future<SearchSpecialistsResultModel> searchSpecialists({
    required String skill,
    String? postalCode,
    int page = 1,
    int limit = 10,
  });

  Future<GeoInfoModel> getGeoInfo(String postalCode);
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final ApiClient apiClient;

  SearchRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<SearchSpecialistsResultModel> searchSpecialists({
    required String skill,
    String? postalCode,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await apiClient.get(
      ApiConstants.searchSpecialists,
      queryParameters: {
        'skill': skill.trim(),
        if (postalCode != null && postalCode.trim().isNotEmpty)
          'postalCode': postalCode.trim(),
        'page': page,
        'limit': limit,
      },
    );

    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return SearchSpecialistsResultModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /search/specialists: $payload');
  }

  @override
  Future<GeoInfoModel> getGeoInfo(String postalCode) async {
    final response = await apiClient.get(
      ApiConstants.searchGeoInfo(postalCode.trim()),
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return GeoInfoModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /search/geo-info: $payload');
  }
}
