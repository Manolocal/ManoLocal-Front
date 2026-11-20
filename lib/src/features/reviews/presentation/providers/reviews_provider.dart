import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/review_models.dart';
import '../../domain/repositories/reviews_repository.dart';

/// Provider de reseñas públicas (`GET /reviews/specialist/:id`) y publicación de calificaciones (`POST /reviews`).
class ReviewsProvider extends ChangeNotifier {
  final ReviewsRepository reviewsRepository;

  String? _activeSpecialistId;
  SpecialistReputationSummaryModel? _specialistSummary;
  List<ReviewModel> _reviews = const [];
  PaginationMeta? _meta;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  bool _isSubmitting = false;
  String? _submitError;

  ReviewsProvider({required this.reviewsRepository});

  String? get activeSpecialistId => _activeSpecialistId;
  SpecialistReputationSummaryModel? get specialistSummary => _specialistSummary;
  List<ReviewModel> get reviews => _reviews;
  PaginationMeta? get meta => _meta;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _meta?.hasNext ?? false;

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;

  Future<bool> loadSpecialistReviews(
    String specialistId, {
    int limit = 10,
  }) async {
    _activeSpecialistId = specialistId;
    _isLoading = true;
    _errorMessage = null;
    _reviews = const [];
    _meta = null;
    notifyListeners();

    try {
      final result = await reviewsRepository.getReviewsBySpecialist(
        specialistId,
        page: 1,
        limit: limit,
      );
      _specialistSummary = result.specialist;
      _reviews = result.reviews;
      _meta = result.meta;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMoreSpecialistReviews() async {
    final specialistId = _activeSpecialistId;
    if (specialistId == null || _isLoadingMore || !hasMore) return;

    final nextPage = (_meta?.page ?? 1) + 1;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await reviewsRepository.getReviewsBySpecialist(
        specialistId,
        page: nextPage,
        limit: _meta?.limit ?? 10,
      );
      _specialistSummary = result.specialist;
      _reviews = [..._reviews, ...result.reviews];
      _meta = result.meta;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<CreateReviewResultModel?> submitReview({
    required String jobAgreementId,
    required int rating,
    String? comment,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final result = await reviewsRepository.createReview(
        CreateReviewRequestModel(
          jobAgreementId: jobAgreementId,
          rating: rating,
          comment: comment,
        ),
      );

      // Si actualmente estamos viendo el perfil de ese especialista, actualizar lista en memoria
      if (_activeSpecialistId == result.review.specialistId) {
        _specialistSummary = SpecialistReputationSummaryModel(
          id: result.specialistReputation.id.isNotEmpty
              ? result.specialistReputation.id
              : result.review.specialistId,
          name: _specialistSummary?.name,
          fullName: _specialistSummary?.fullName,
          ratingAverage: result.specialistReputation.ratingAverage,
          ratingCount: result.specialistReputation.ratingCount,
        );
        _reviews = [result.review, ..._reviews];
      }

      _isSubmitting = false;
      notifyListeners();
      return result;
    } catch (e) {
      _submitError = _extractErrorMessage(e);
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  Future<JobReviewStatusModel?> getReviewByJob(String jobAgreementId) async {
    try {
      return await reviewsRepository.getReviewByJob(jobAgreementId);
    } catch (_) {
      return null;
    }
  }

  void clearSubmitError() {
    if (_submitError != null) {
      _submitError = null;
      notifyListeners();
    }
  }

  void clear() {
    _activeSpecialistId = null;
    _specialistSummary = null;
    _reviews = const [];
    _meta = null;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _isSubmitting = false;
    _submitError = null;
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
