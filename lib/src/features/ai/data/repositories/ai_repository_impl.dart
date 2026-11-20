import 'dart:typed_data';
import '../../domain/models/ai_models.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_data_source.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource remoteDataSource;

  AiRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DocumentVerificationModel> verifyDocument({
    required String knowledgeId,
    required String documentFilePath,
    Uint8List? documentBytes,
    String? documentFileName,
  }) {
    return remoteDataSource.verifyDocument(
      knowledgeId: knowledgeId,
      documentFilePath: documentFilePath,
      documentBytes: documentBytes,
      documentFileName: documentFileName,
    );
  }

  @override
  Future<List<DocumentVerificationModel>> getKnowledgeVerifications(
    String knowledgeId,
  ) {
    return remoteDataSource.getKnowledgeVerifications(knowledgeId);
  }

  @override
  Future<AiStatusModel> getStatus() => remoteDataSource.getStatus();

  @override
  Future<AiGenerateTextResultModel> generateText(String prompt) {
    return remoteDataSource.generateText(prompt);
  }
}
