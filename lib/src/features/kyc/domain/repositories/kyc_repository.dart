import '../models/kyc_models.dart';

/// Contrato de repositorio para la carga de documentos KYC (INE y selfie).
abstract class KycRepository {
  Future<KycUploadResultModel> uploadDocuments({
    required String ineFilePath,
    required String selfieFilePath,
  });
}
