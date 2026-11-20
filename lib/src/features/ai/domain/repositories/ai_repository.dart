import 'dart:typed_data';
import '../models/ai_models.dart';

/// Contrato de repositorio para los servicios de Inteligencia Artificial y OCR.
abstract class AiRepository {
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
