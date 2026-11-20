import '../../domain/models/review_models.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../datasources/reviews_remote_data_source.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsRemoteDataSource remoteDataSource;

  ReviewsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<CreateReviewResultModel> createReview(
    CreateReviewRequestModel request,
  ) {
    return remoteDataSource.createReview(request);
  }

  @override
  Future<SpecialistReviewsPageModel> getReviewsBySpecialist(
    String specialistId, {
    int page = 1,
    int limit = 10,
  }) {
    return remoteDataSource.getReviewsBySpecialist(
      specialistId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<JobReviewStatusModel> getReviewByJob(String jobAgreementId) {
    return remoteDataSource.getReviewByJob(jobAgreementId);
  }
}
