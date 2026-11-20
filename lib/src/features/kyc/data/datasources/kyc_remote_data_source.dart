import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/file_upload_helper.dart';
import '../../domain/models/kyc_models.dart';

abstract class KycRemoteDataSource {
  Future<KycUploadResultModel> uploadDocuments({
    required String ineFilePath,
    required String selfieFilePath,
    Uint8List? ineBytes,
    String? ineFileName,
    Uint8List? selfieBytes,
    String? selfieFileName,
  });
}

class KycRemoteDataSourceImpl implements KycRemoteDataSource {
  final ApiClient apiClient;

  KycRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<KycUploadResultModel> uploadDocuments({
    required String ineFilePath,
    required String selfieFilePath,
    Uint8List? ineBytes,
    String? ineFileName,
    Uint8List? selfieBytes,
    String? selfieFileName,
  }) async {
    final ineFile = await FileUploadHelper.fromPathOrBytes(
      filePath: ineFilePath,
      bytes: ineBytes,
      fileName: ineFileName,
      defaultName: 'ine.jpg',
    );
    final selfieFile = await FileUploadHelper.fromPathOrBytes(
      filePath: selfieFilePath,
      bytes: selfieBytes,
      fileName: selfieFileName,
      defaultName: 'selfie.jpg',
    );

    final formData = FormData.fromMap({
      'ine': ineFile,
      'selfie': selfieFile,
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
