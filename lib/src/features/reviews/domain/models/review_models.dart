import '../../../../core/models/paginated_response.dart';

/// Autor visible de una reseña pública.
class ReviewAuthorModel {
  final String id;
  final String name;

  const ReviewAuthorModel({
    required this.id,
    required this.name,
  });

  factory ReviewAuthorModel.fromJson(Map<String, dynamic> json) {
    return ReviewAuthorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Empleador',
    );
  }
}

/// Reseña pública asociada a un acuerdo de trabajo completado.
class ReviewModel {
  final String id;
  final String jobAgreementId;
  final String employerId;
  final String specialistId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final String? jobTitle;
  final ReviewAuthorModel employer;

  const ReviewModel({
    required this.id,
    required this.jobAgreementId,
    required this.employerId,
    required this.specialistId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.jobTitle,
    required this.employer,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawEmployer = json['employer'];
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      jobAgreementId: json['jobAgreementId']?.toString() ?? '',
      employerId: json['employerId']?.toString() ?? '',
      specialistId: json['specialistId']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      jobTitle: json['jobTitle']?.toString(),
      employer: rawEmployer is Map<String, dynamic>
          ? ReviewAuthorModel.fromJson(rawEmployer)
          : ReviewAuthorModel(
              id: json['employerId']?.toString() ?? '',
              name: 'Empleador',
            ),
    );
  }
}

/// Resumen de reputación pública del especialista.
class SpecialistReputationSummaryModel {
  final String id;
  final String? name;
  final String? fullName;
  final double ratingAverage;
  final int ratingCount;

  const SpecialistReputationSummaryModel({
    required this.id,
    this.name,
    this.fullName,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
  });

  String get displayName {
    final f = fullName?.trim();
    if (f != null && f.isNotEmpty) return f;
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Especialista';
  }

  factory SpecialistReputationSummaryModel.fromJson(Map<String, dynamic> json) {
    return SpecialistReputationSummaryModel(
      id: (json['id'] ?? json['specialistId'])?.toString() ?? '',
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

/// Respuesta paginada pública de `GET /reviews/specialist/:specialistId`.
class SpecialistReviewsPageModel {
  final SpecialistReputationSummaryModel specialist;
  final List<ReviewModel> reviews;
  final PaginationMeta meta;

  const SpecialistReviewsPageModel({
    required this.specialist,
    required this.reviews,
    required this.meta,
  });

  factory SpecialistReviewsPageModel.fromJson(Map<String, dynamic> json) {
    final rawSpecialist = json['specialist'];
    final rawReviews = json['reviews'];
    final rawMeta = json['meta'];

    final reviews = rawReviews is List
        ? rawReviews
            .whereType<Map<String, dynamic>>()
            .map(ReviewModel.fromJson)
            .toList()
        : const <ReviewModel>[];

    return SpecialistReviewsPageModel(
      specialist: rawSpecialist is Map<String, dynamic>
          ? SpecialistReputationSummaryModel.fromJson(rawSpecialist)
          : const SpecialistReputationSummaryModel(id: ''),
      reviews: reviews,
      meta: rawMeta is Map<String, dynamic>
          ? PaginationMeta.fromJson(rawMeta)
          : PaginationMeta(
              total: reviews.length,
              page: 1,
              limit: 10,
              totalPages: reviews.isEmpty ? 0 : 1,
              hasNext: false,
              hasPrev: false,
            ),
    );
  }
}

/// Respuesta de `GET /reviews/job/:jobAgreementId`.
class JobReviewStatusModel {
  final String jobAgreementId;
  final bool hasReview;
  final ReviewModel? review;

  const JobReviewStatusModel({
    required this.jobAgreementId,
    required this.hasReview,
    this.review,
  });

  factory JobReviewStatusModel.fromJson(Map<String, dynamic> json) {
    final rawReview = json['review'];
    return JobReviewStatusModel(
      jobAgreementId: json['jobAgreementId']?.toString() ?? '',
      hasReview: (json['hasReview'] as bool?) ?? (rawReview != null),
      review: rawReview is Map<String, dynamic>
          ? ReviewModel.fromJson(rawReview)
          : null,
    );
  }
}

/// Payload para crear una reseña (`POST /reviews`).
class CreateReviewRequestModel {
  final String jobAgreementId;
  final int rating;
  final String? comment;

  const CreateReviewRequestModel({
    required this.jobAgreementId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    final trimmed = comment?.trim();
    return {
      'jobAgreementId': jobAgreementId,
      'rating': rating,
      if (trimmed != null && trimmed.isNotEmpty) 'comment': trimmed,
    };
  }
}

/// Respuesta al publicar una reseña (`POST /reviews`).
class CreateReviewResultModel {
  final String message;
  final ReviewModel review;
  final SpecialistReputationSummaryModel specialistReputation;

  const CreateReviewResultModel({
    required this.message,
    required this.review,
    required this.specialistReputation,
  });

  factory CreateReviewResultModel.fromJson(Map<String, dynamic> json) {
    final rawReview = json['review'];
    final rawRep = json['specialistReputation'];
    return CreateReviewResultModel(
      message: json['message']?.toString() ?? 'Reseña publicada exitosamente',
      review: rawReview is Map<String, dynamic>
          ? ReviewModel.fromJson(rawReview)
          : ReviewModel.fromJson(const {}),
      specialistReputation: rawRep is Map<String, dynamic>
          ? SpecialistReputationSummaryModel.fromJson(rawRep)
          : const SpecialistReputationSummaryModel(id: ''),
    );
  }
}
