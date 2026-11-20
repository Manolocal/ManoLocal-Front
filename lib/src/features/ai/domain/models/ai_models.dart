import '../../../../core/enums/backend_enums.dart';

/// Resultado de verificación OCR/Gemini de un certificado de oficio.
class DocumentVerificationModel {
  final String id;
  final String knowledgeId;
  final String fileUrl;
  final DocumentVerificationStatus status;
  final String? provider;
  final double? score;
  final String? reason;
  final DateTime? createdAt;

  const DocumentVerificationModel({
    required this.id,
    required this.knowledgeId,
    required this.fileUrl,
    required this.status,
    this.provider,
    this.score,
    this.reason,
    this.createdAt,
  });

  factory DocumentVerificationModel.fromJson(Map<String, dynamic> json) {
    return DocumentVerificationModel(
      id: json['id']?.toString() ?? '',
      knowledgeId: json['knowledgeId']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      status: DocumentVerificationStatus.fromString(json['status']?.toString()),
      provider: json['provider']?.toString(),
      score: (json['score'] as num?)?.toDouble(),
      reason: json['reason']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

/// Estado del proveedor Google Gemini AI en el backend (`GET /ai/status`).
class AiStatusModel {
  final String provider;
  final bool isConfigured;
  final String model;

  const AiStatusModel({
    required this.provider,
    required this.isConfigured,
    required this.model,
  });

  factory AiStatusModel.fromJson(Map<String, dynamic> json) {
    return AiStatusModel(
      provider: json['provider']?.toString() ?? 'google-gemini',
      isConfigured: (json['isConfigured'] as bool?) ?? false,
      model: json['model']?.toString() ?? '',
    );
  }
}

/// Respuesta de generación de texto libre con Gemini (`POST /ai/generate-text`).
class AiGenerateTextResultModel {
  final String prompt;
  final String response;

  const AiGenerateTextResultModel({
    required this.prompt,
    required this.response,
  });

  factory AiGenerateTextResultModel.fromJson(Map<String, dynamic> json) {
    return AiGenerateTextResultModel(
      prompt: json['prompt']?.toString() ?? '',
      response: json['response']?.toString() ?? '',
    );
  }
}
