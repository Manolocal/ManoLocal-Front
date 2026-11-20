import 'dart:typed_data';
import '../models/catalog_models.dart';

/// Contrato de repositorio para el catálogo de fotografías de trabajos.
abstract class CatalogRepository {
  Future<UploadCatalogImageResultModel> uploadImage({
    required String filePath,
    required String title,
    String? description,
    Uint8List? fileBytes,
    String? fileName,
  });

  Future<MyCatalogModel> getMyImages();

  Future<SpecialistCatalogModel> getSpecialistImages(String specialistId);

  Future<String> deleteImage(String imageId);
}
