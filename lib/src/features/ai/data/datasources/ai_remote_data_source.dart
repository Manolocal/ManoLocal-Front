import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/file_upload_helper.dart';
import '../../domain/models/ai_models.dart';

abstract class AiRemoteDataSource {
  Future<DocumentVerificationModel> verifyDocument({
    required String knowledgeId,
    required String documentFilePath,
    Uint8List? documentBytes,
    String? documentFileName,
  });

  Future<List<DocumentVerificationModel>> getKnowledgeVerifications(
    String knowledgeId,
  );

  Future<AiStatusModel> getStatus();

  Future<AiGenerateTextResultModel> generateText(String prompt);
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final ApiClient apiClient;

  AiRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<DocumentVerificationModel> verifyDocument({
    required String knowledgeId,
    required String documentFilePath,
    Uint8List? documentBytes,
    String? documentFileName,
  }) async {
    final docFile = await FileUploadHelper.fromPathOrBytes(
      filePath: documentFilePath,
      bytes: documentBytes,
      fileName: documentFileName,
      defaultName: 'certificado.pdf',
    );

    final formData = FormData.fromMap({
      'knowledgeId': knowledgeId,
      'document': docFile,
    });

    final response = await apiClient.postMultipart(
      ApiConstants.aiVerifyDocument,
      formData: formData,
    );

    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return DocumentVerificationModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /ai/verify-document: $payload');
  }

  @override
  Future<List<DocumentVerificationModel>> getKnowledgeVerifications(
    String knowledgeId,
  ) async {
    final response = await apiClient.get(
      ApiConstants.aiKnowledgeVerifications(knowledgeId),
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(DocumentVerificationModel.fromJson)
          .toList();
    }
    throw FormatException(
      'Respuesta inválida en /ai/knowledge/$knowledgeId/verifications: $payload',
    );
  }

  @override
  Future<AiStatusModel> getStatus() async {
    final response = await apiClient.get(
      ApiConstants.aiStatus,
      options: Options(extra: const {'requiresAuth': false}),
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return AiStatusModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /ai/status: $payload');
  }

  @override
  Future<AiGenerateTextResultModel> generateText(String prompt) async {
    final response = await apiClient.post(
      ApiConstants.aiGenerateText,
      data: {'prompt': prompt},
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return AiGenerateTextResultModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /ai/generate-text: $payload');
  }
}
