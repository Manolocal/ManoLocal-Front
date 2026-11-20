/// Fotografía de trabajo en el catálogo de un especialista.
class CatalogImageModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String title;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CatalogImageModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.title,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CatalogImageModel.fromJson(Map<String, dynamic> json) {
    return CatalogImageModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

/// Estado de cuota de imágenes (máximo 10 activas por especialista).
class CatalogQuotaModel {
  final int active;
  final int limit;
  final int remaining;

  const CatalogQuotaModel({
    required this.active,
    required this.limit,
    required this.remaining,
  });

  factory CatalogQuotaModel.fromJson(Map<String, dynamic> json) {
    return CatalogQuotaModel(
      active: (json['active'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      remaining: (json['remaining'] as num?)?.toInt() ?? 10,
    );
  }
}

/// Respuesta al subir una fotografía al catálogo (`POST /catalog/images`).
class UploadCatalogImageResultModel {
  final String message;
  final CatalogImageModel image;
  final CatalogQuotaModel quota;

  const UploadCatalogImageResultModel({
    required this.message,
    required this.image,
    required this.quota,
  });

  factory UploadCatalogImageResultModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image'];
    final rawQuota = json['quota'];

    return UploadCatalogImageResultModel(
      message: json['message']?.toString() ?? '',
      image: rawImage is Map<String, dynamic>
          ? CatalogImageModel.fromJson(rawImage)
          : const CatalogImageModel(
              id: '',
              userId: '',
              imageUrl: '',
              title: '',
            ),
      quota: rawQuota is Map<String, dynamic>
          ? CatalogQuotaModel.fromJson(rawQuota)
          : const CatalogQuotaModel(active: 0, limit: 10, remaining: 10),
    );
  }
}

/// Catálogo propio del especialista autenticado (`GET /catalog/me`).
class MyCatalogModel {
  final List<CatalogImageModel> images;
  final CatalogQuotaModel quota;

  const MyCatalogModel({
    required this.images,
    required this.quota,
  });

  factory MyCatalogModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final rawQuota = json['quota'];

    return MyCatalogModel(
      images: rawImages is List
          ? rawImages
              .whereType<Map<String, dynamic>>()
              .map(CatalogImageModel.fromJson)
              .toList()
          : const [],
      quota: rawQuota is Map<String, dynamic>
          ? CatalogQuotaModel.fromJson(rawQuota)
          : const CatalogQuotaModel(active: 0, limit: 10, remaining: 10),
    );
  }
}

/// Resumen público de especialista en `GET /catalog/specialist/:specialistId`.
class SpecialistCatalogPreviewModel {
  final String id;
  final String? name;
  final String? fullName;
  final double ratingAverage;
  final int ratingCount;

  const SpecialistCatalogPreviewModel({
    required this.id,
    this.name,
    this.fullName,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
  });

  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final raw = name?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'Especialista';
  }

  factory SpecialistCatalogPreviewModel.fromJson(Map<String, dynamic> json) {
    return SpecialistCatalogPreviewModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      fullName: json['fullName']?.toString(),
      ratingAverage: double.tryParse(
            json['ratingAverage']?.toString() ?? '',
          ) ??
          (json['ratingAverage'] as num?)?.toDouble() ??
          0.0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Portafolio público de un especialista (`GET /catalog/specialist/:specialistId`).
class SpecialistCatalogModel {
  final SpecialistCatalogPreviewModel specialist;
  final List<CatalogImageModel> images;

  const SpecialistCatalogModel({
    required this.specialist,
    required this.images,
  });

  factory SpecialistCatalogModel.fromJson(Map<String, dynamic> json) {
    final rawSpecialist = json['specialist'];
    final rawImages = json['images'];

    return SpecialistCatalogModel(
      specialist: rawSpecialist is Map<String, dynamic>
          ? SpecialistCatalogPreviewModel.fromJson(rawSpecialist)
          : const SpecialistCatalogPreviewModel(id: ''),
      images: rawImages is List
          ? rawImages
              .whereType<Map<String, dynamic>>()
              .map(CatalogImageModel.fromJson)
              .toList()
          : const [],
    );
  }
}
