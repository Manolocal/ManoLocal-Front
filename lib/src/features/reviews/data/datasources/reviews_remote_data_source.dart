import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/review_models.dart';

abstract class ReviewsRemoteDataSource {
  Future<CreateReviewResultModel> createReview(
    CreateReviewRequestModel request,
  );

  Future<SpecialistReviewsPageModel> getReviewsBySpecialist(
    String specialistId, {
    int page = 1,
    int limit = 10,
  });

  Future<JobReviewStatusModel> getReviewByJob(String jobAgreementId);
}

class ReviewsRemoteDataSourceImpl implements ReviewsRemoteDataSource {
  final ApiClient apiClient;

  ReviewsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<CreateReviewResultModel> createReview(
    CreateReviewRequestModel request,
  ) async {
    final response = await apiClient.post(
      ApiConstants.reviews,
      data: request.toJson(),
    );
    return CreateReviewResultModel.fromJson(_unwrapMap(response.data));
  }

  @override
  Future<SpecialistReviewsPageModel> getReviewsBySpecialist(
    String specialistId, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await apiClient.get(
      ApiConstants.reviewsBySpecialist(specialistId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return SpecialistReviewsPageModel.fromJson(_unwrapMap(response.data));
  }

  @override
  Future<JobReviewStatusModel> getReviewByJob(String jobAgreementId) async {
    final response = await apiClient.get(
      ApiConstants.reviewByJob(jobAgreementId),
    );
    return JobReviewStatusModel.fromJson(_unwrapMap(response.data));
  }

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    final payload = ApiClient.unwrapData(raw);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    throw FormatException('Respuesta inválida del servidor en /reviews: $payload');
  }
}
