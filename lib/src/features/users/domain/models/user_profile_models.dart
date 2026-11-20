import '../../../../core/enums/backend_enums.dart';

/// Perfil personal y documentos KYC de un usuario (`/users/me`).
class ProfileModel {
  final String id;
  final String userId;
  final String? fullName;
  final String? phone;
  final String? address;
  final String? postalCode;
  final String? ineUrl;
  final String? selfieUrl;
  final double ratingAverage;
  final int ratingCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.phone,
    this.address,
    this.postalCode,
    this.ineUrl,
    this.selfieUrl,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      postalCode: json['postalCode']?.toString(),
      ineUrl: json['ineUrl']?.toString(),
      selfieUrl: json['selfieUrl']?.toString(),
      ratingAverage: double.tryParse(
            json['ratingAverage']?.toString() ?? '',
          ) ??
          (json['ratingAverage'] as num?)?.toDouble() ??
          0.0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

/// Resumen de verificación de un conocimiento incluido dentro de `/users/me`.
class KnowledgeVerificationSummaryModel {
  final String id;
  final DocumentVerificationStatus status;
  final String? provider;
  final double? score;
  final String? fileUrl;
  final DateTime? createdAt;

  const KnowledgeVerificationSummaryModel({
    required this.id,
    required this.status,
    this.provider,
    this.score,
    this.fileUrl,
    this.createdAt,
  });

  factory KnowledgeVerificationSummaryModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeVerificationSummaryModel(
      id: json['id']?.toString() ?? '',
      status: DocumentVerificationStatus.fromString(json['status']?.toString()),
      provider: json['provider']?.toString(),
      score: (json['score'] as num?)?.toDouble(),
      fileUrl: json['fileUrl']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

/// Conocimiento u oficio registrado por un ESPECIALISTA.
class KnowledgeModel {
  final String id;
  final String name;
  final List<KnowledgeVerificationSummaryModel> verifications;

  const KnowledgeModel({
    required this.id,
    required this.name,
    this.verifications = const [],
  });

  factory KnowledgeModel.fromJson(Map<String, dynamic> json) {
    final rawVerifications = json['verifications'];
    final verifications = rawVerifications is List
        ? rawVerifications
            .whereType<Map<String, dynamic>>()
            .map(KnowledgeVerificationSummaryModel.fromJson)
            .toList()
        : <KnowledgeVerificationSummaryModel>[];

    return KnowledgeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      verifications: verifications,
    );
  }
}

/// Respuesta completa del endpoint `GET /users/me` y `PATCH /users/me/profile`.
class UserMeModel {
  final String id;
  final String email;
  final String? name;
  final UserRole role;
  final UserStatus status;
  final DateTime? createdAt;
  final ProfileModel? profile;
  final List<KnowledgeModel> knowledges;

  const UserMeModel({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.status,
    this.createdAt,
    this.profile,
    this.knowledges = const [],
  });

  String get displayName =>
      profile?.fullName ??
      ((name != null && name!.trim().isNotEmpty) ? name!.trim() : email);

  factory UserMeModel.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['profile'];
    final rawKnowledges = json['knowledges'];

    return UserMeModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      role: UserRole.fromString(json['role']?.toString()),
      status: UserStatus.fromString(json['status']?.toString()),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      profile: rawProfile is Map<String, dynamic>
          ? ProfileModel.fromJson(rawProfile)
          : null,
      knowledges: rawKnowledges is List
          ? rawKnowledges
              .whereType<Map<String, dynamic>>()
              .map(KnowledgeModel.fromJson)
              .toList()
          : const [],
    );
  }
}

/// DTO para `PATCH /users/me/profile` (`UpdateProfileDto`).
class UpdateProfileRequestModel {
  final String? fullName;
  final String? phone;
  final String? address;
  final String? postalCode;

  const UpdateProfileRequestModel({
    this.fullName,
    this.phone,
    this.address,
    this.postalCode,
  });

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'fullName': fullName!.trim(),
        if (phone != null) 'phone': phone!.trim(),
        if (address != null) 'address': address!.trim(),
        if (postalCode != null) 'postalCode': postalCode!.trim(),
      };
}
