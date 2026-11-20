import 'dart:typed_data';
import '../../domain/models/catalog_models.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_data_source.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogRemoteDataSource remoteDataSource;

  CatalogRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UploadCatalogImageResultModel> uploadImage({
    required String filePath,
    required String title,
    String? description,
    Uint8List? fileBytes,
    String? fileName,
  }) {
    return remoteDataSource.uploadImage(
      filePath: filePath,
      title: title,
      description: description,
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }

  @override
  Future<MyCatalogModel> getMyImages() => remoteDataSource.getMyImages();

  @override
  Future<SpecialistCatalogModel> getSpecialistImages(String specialistId) {
    return remoteDataSource.getSpecialistImages(specialistId);
  }

  @override
  Future<String> deleteImage(String imageId) {
    return remoteDataSource.deleteImage(imageId);
  }
}
