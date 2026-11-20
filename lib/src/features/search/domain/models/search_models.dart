import '../../../../core/enums/backend_enums.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../users/domain/models/user_profile_models.dart';

/// Perfil resumido devuelto dentro de la búsqueda geolocalizada de especialistas.
class SpecialistProfilePreviewModel {
  final String? fullName;
  final String? phone;
  final String? address;
  final String? postalCode;

  const SpecialistProfilePreviewModel({
    this.fullName,
    this.phone,
    this.address,
    this.postalCode,
  });

  factory SpecialistProfilePreviewModel.fromJson(Map<String, dynamic> json) {
    return SpecialistProfilePreviewModel(
      fullName: json['fullName']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      postalCode: json['postalCode']?.toString(),
    );
  }
}

/// Especialista encontrado en `GET /search/specialists`.
class SpecialistSearchItemModel {
  final String id;
  final String email;
  final String? name;
  final UserStatus status;
  final DateTime? createdAt;
  final SpecialistProfilePreviewModel? profile;
  final List<KnowledgeModel> knowledges;

  const SpecialistSearchItemModel({
    required this.id,
    required this.email,
    this.name,
    required this.status,
    this.createdAt,
    this.profile,
    this.knowledges = const [],
  });

  String get displayName => profile?.fullName ?? name ?? email;

  factory SpecialistSearchItemModel.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['profile'];
    final rawKnowledges = json['knowledges'];

    return SpecialistSearchItemModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      status: UserStatus.fromString(json['status']?.toString()),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      profile: rawProfile is Map<String, dynamic>
          ? SpecialistProfilePreviewModel.fromJson(rawProfile)
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

/// Metadatos del filtro municipal SEPOMEX/Copomex aplicado en la búsqueda.
class GeoFilterModel {
  final String searchedPostalCode;
  final String municipio;
  final int totalPostalCodesInMunicipality;

  const GeoFilterModel({
    required this.searchedPostalCode,
    required this.municipio,
    required this.totalPostalCodesInMunicipality,
  });

  factory GeoFilterModel.fromJson(Map<String, dynamic> json) {
    return GeoFilterModel(
      searchedPostalCode: json['searchedPostalCode']?.toString() ?? '',
      municipio: json['municipio']?.toString() ?? '',
      totalPostalCodesInMunicipality:
          (json['totalPostalCodesInMunicipality'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Respuesta de `GET /search/specialists`.
class SearchSpecialistsResultModel {
  final List<SpecialistSearchItemModel> specialists;
  final GeoFilterModel geoFilter;
  final PaginationMeta pagination;

  const SearchSpecialistsResultModel({
    required this.specialists,
    required this.geoFilter,
    required this.pagination,
  });

  factory SearchSpecialistsResultModel.fromJson(Map<String, dynamic> json) {
    final paginated = PaginatedResponse<SpecialistSearchItemModel>.fromJson(
      json,
      SpecialistSearchItemModel.fromJson,
      itemsKey: 'specialists',
      metaKey: 'pagination',
    );
    final rawGeo = json['geoFilter'];

    return SearchSpecialistsResultModel(
      specialists: paginated.items,
      geoFilter: rawGeo is Map<String, dynamic>
          ? GeoFilterModel.fromJson(rawGeo)
          : const GeoFilterModel(
              searchedPostalCode: '',
              municipio: '',
              totalPostalCodesInMunicipality: 0,
            ),
      pagination: paginated.meta,
    );
  }
}

/// Respuesta de `GET /search/geo-info/:cp`.
class GeoInfoModel {
  final String municipio;
  final List<String> postalCodes;

  const GeoInfoModel({
    required this.municipio,
    required this.postalCodes,
  });

  factory GeoInfoModel.fromJson(Map<String, dynamic> json) {
    final rawCps = json['postalCodes'];
    return GeoInfoModel(
      municipio: json['municipio']?.toString() ?? '',
      postalCodes: rawCps is List
          ? rawCps.map((e) => e.toString()).toList()
          : const [],
    );
  }
}
