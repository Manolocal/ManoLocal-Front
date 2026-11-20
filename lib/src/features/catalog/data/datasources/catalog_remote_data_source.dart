import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/catalog_models.dart';

abstract class CatalogRemoteDataSource {
  Future<UploadCatalogImageResultModel> uploadImage({
    required String filePath,
    required String title,
    String? description,
  });

  Future<MyCatalogModel> getMyImages();

  Future<SpecialistCatalogModel> getSpecialistImages(String specialistId);

  Future<String> deleteImage(String imageId);
}

class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  final ApiClient apiClient;

  CatalogRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UploadCatalogImageResultModel> uploadImage({
    required String filePath,
    required String title,
    String? description,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    });

    final response = await apiClient.postMultipart(
      ApiConstants.catalogImages,
      formData: formData,
    );

    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return UploadCatalogImageResultModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /catalog/images: $payload');
  }

  @override
  Future<MyCatalogModel> getMyImages() async {
    final response = await apiClient.get(ApiConstants.catalogMe);
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return MyCatalogModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /catalog/me: $payload');
  }

  @override
  Future<SpecialistCatalogModel> getSpecialistImages(String specialistId) async {
    final response = await apiClient.get(
      ApiConstants.catalogSpecialist(specialistId),
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return SpecialistCatalogModel.fromJson(payload);
    }
    throw FormatException(
      'Respuesta inválida en /catalog/specialist/$specialistId: $payload',
    );
  }

  @override
  Future<String> deleteImage(String imageId) async {
    final response = await apiClient.delete(
      ApiConstants.catalogDeleteImage(imageId),
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return payload['message']?.toString() ??
          'Foto eliminada exitosamente del catálogo';
    }
    return 'Foto eliminada exitosamente del catálogo';
  }
}
