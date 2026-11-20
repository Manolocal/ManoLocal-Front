import '../models/review_models.dart';

/// Contrato de acceso a reseñas y reputación de especialistas.
abstract class ReviewsRepository {
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
