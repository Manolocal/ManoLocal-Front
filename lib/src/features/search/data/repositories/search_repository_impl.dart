import '../../domain/models/search_models.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SearchSpecialistsResultModel> searchSpecialists({
    required String skill,
    String? postalCode,
    int page = 1,
    int limit = 10,
  }) {
    return remoteDataSource.searchSpecialists(
      skill: skill,
      postalCode: postalCode,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<GeoInfoModel> getGeoInfo(String postalCode) {
    return remoteDataSource.getGeoInfo(postalCode);
  }
}
