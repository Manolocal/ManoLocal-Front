import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/kyc_models.dart';

abstract class KycRemoteDataSource {
  Future<KycUploadResultModel> uploadDocuments({
    required String ineFilePath,
    required String selfieFilePath,
  });
}

class KycRemoteDataSourceImpl implements KycRemoteDataSource {
  final ApiClient apiClient;

  KycRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<KycUploadResultModel> uploadDocuments({
    required String ineFilePath,
    required String selfieFilePath,
  }) async {
    final formData = FormData.fromMap({
      'ine': await MultipartFile.fromFile(ineFilePath),
      'selfie': await MultipartFile.fromFile(selfieFilePath),
    });

    final response = await apiClient.postMultipart(
      ApiConstants.kycDocuments,
      formData: formData,
    );

    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return KycUploadResultModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /kyc/documents: $payload');
  }
}
