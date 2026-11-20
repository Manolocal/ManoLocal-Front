import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/ai_models.dart';
import '../../domain/repositories/ai_repository.dart';

/// Mensaje en la conversación local con el Asistente Gemini AI.
class AiAssistantTurn {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const AiAssistantTurn({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Provider para Gemini AI: estado del motor, asistente de texto y verificación OCR de certificados.
class AiProvider extends ChangeNotifier {
  final AiRepository aiRepository;

  AiStatusModel? _status;
  final List<AiAssistantTurn> _turns = [];
  final Map<String, List<DocumentVerificationModel>> _verificationsByKnowledge =
      {};

  bool _isLoadingStatus = false;
  bool _isGenerating = false;
  bool _isVerifyingDocument = false;
  bool _isLoadingVerifications = false;
  String? _errorMessage;

  AiProvider({required this.aiRepository});

  AiStatusModel? get status => _status;
  List<AiAssistantTurn> get turns => List.unmodifiable(_turns);
  bool get isLoadingStatus => _isLoadingStatus;
  bool get isGenerating => _isGenerating;
  bool get isVerifyingDocument => _isVerifyingDocument;
  bool get isLoadingVerifications => _isLoadingVerifications;
  String? get errorMessage => _errorMessage;

  List<DocumentVerificationModel> verificationsFor(String knowledgeId) =>
      _verificationsByKnowledge[knowledgeId] ?? const [];

  Future<void> loadStatus() async {
    _isLoadingStatus = true;
    notifyListeners();

    try {
      _status = await aiRepository.getStatus();
    } catch (_) {
      // Estado opcional informativo.
    } finally {
      _isLoadingStatus = false;
      notifyListeners();
    }
  }

  Future<bool> askAssistant(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return false;

    _turns.add(
      AiAssistantTurn(text: trimmed, isUser: true, timestamp: DateTime.now()),
    );
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await aiRepository.generateText(trimmed);
      _turns.add(
        AiAssistantTurn(
          text: result.response,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isGenerating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  Future<DocumentVerificationModel?> verifyCertificate({
    required String knowledgeId,
    required String filePath,
    Uint8List? bytes,
    String? fileName,
  }) async {
    _isVerifyingDocument = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final verification = await aiRepository.verifyDocument(
        knowledgeId: knowledgeId,
        documentFilePath: filePath,
        documentBytes: bytes,
        documentFileName: fileName,
      );
      final current = [
        ...(_verificationsByKnowledge[knowledgeId] ??
            const <DocumentVerificationModel>[]),
      ];
      current.insert(0, verification);
      _verificationsByKnowledge[knowledgeId] = current;
      _isVerifyingDocument = false;
      notifyListeners();
      return verification;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isVerifyingDocument = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<DocumentVerificationModel>> loadKnowledgeVerifications(
    String knowledgeId,
  ) async {
    _isLoadingVerifications = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await aiRepository.getKnowledgeVerifications(knowledgeId);
      _verificationsByKnowledge[knowledgeId] = list;
      _isLoadingVerifications = false;
      notifyListeners();
      return list;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoadingVerifications = false;
      notifyListeners();
      return const [];
    }
  }

  void clearConversation() {
    _turns.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    _turns.clear();
    _verificationsByKnowledge.clear();
    _errorMessage = null;
    _isGenerating = false;
    _isVerifyingDocument = false;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException && error.error is AppException) {
      return (error.error as AppException).message;
    }
    if (error is AppException) {
      return error.message;
    }
    return error.toString();
  }
}
