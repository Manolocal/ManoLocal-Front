import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:manolocal_front/src/core/enums/backend_enums.dart';
import 'package:manolocal_front/src/core/models/paginated_response.dart';
import 'package:manolocal_front/src/core/theme/app_theme.dart';
import 'package:manolocal_front/src/core/widgets/brand_logo.dart';
import 'package:manolocal_front/src/core/widgets/star_rating_display.dart';
import 'package:manolocal_front/src/features/jobs/domain/models/job_models.dart';
import 'package:manolocal_front/src/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:manolocal_front/src/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:manolocal_front/src/features/reviews/domain/models/review_models.dart';
import 'package:manolocal_front/src/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:manolocal_front/src/features/reviews/presentation/providers/reviews_provider.dart';
import 'package:manolocal_front/src/features/reviews/presentation/widgets/create_review_modal.dart';

class _FakeReviewsRepository implements ReviewsRepository {
  CreateReviewRequestModel? lastSubmitted;
  bool shouldFailSubmit = false;

  @override
  Future<CreateReviewResultModel> createReview(
    CreateReviewRequestModel request,
  ) async {
    lastSubmitted = request;
    if (shouldFailSubmit) {
      throw Exception('Error simulado al publicar reseña');
    }
    return CreateReviewResultModel(
      message: 'Reseña publicada exitosamente',
      review: ReviewModel(
        id: 'rev-new',
        jobAgreementId: request.jobAgreementId,
        employerId: 'emp-1',
        specialistId: 'esp-1',
        rating: request.rating,
        comment: request.comment,
        createdAt: DateTime(2026, 11, 20, 14),
        employer: const ReviewAuthorModel(id: 'emp-1', name: 'Sofía Luna'),
      ),
      specialistReputation: const SpecialistReputationSummaryModel(
        id: 'esp-1',
        ratingAverage: 4.9,
        ratingCount: 4,
      ),
    );
  }

  @override
  Future<JobReviewStatusModel> getReviewByJob(String jobAgreementId) async {
    return JobReviewStatusModel(
      jobAgreementId: jobAgreementId,
      hasReview: false,
    );
  }

  @override
  Future<SpecialistReviewsPageModel> getReviewsBySpecialist(
    String specialistId, {
    int page = 1,
    int limit = 10,
  }) async {
    return SpecialistReviewsPageModel(
      specialist: SpecialistReputationSummaryModel(
        id: specialistId,
        name: 'Carlos López',
        fullName: 'Carlos López Pérez',
        ratingAverage: 4.75,
        ratingCount: 2,
      ),
      reviews: [
        ReviewModel(
          id: 'rev-$page',
          jobAgreementId: 'job-$page',
          employerId: 'emp-$page',
          specialistId: specialistId,
          rating: 5,
          comment: 'Reseña página $page',
          createdAt: DateTime(2026, 11, 20),
          jobTitle: 'Reparación eléctrica',
          employer: ReviewAuthorModel(
            id: 'emp-$page',
            name: 'Cliente $page',
          ),
        ),
      ],
      meta: PaginationMeta(
        total: 2,
        page: page,
        limit: limit,
        totalPages: 2,
        hasNext: page < 2,
        hasPrev: page > 1,
      ),
    );
  }
}

class _StubJobsRepository implements JobsRepository {
  @override
  Future<JobMutationResultModel> cancelJob(String jobId, {String? reason}) =>
      throw UnimplementedError();

  @override
  Future<JobMutationResultModel> completeJob(String jobId) =>
      throw UnimplementedError();

  @override
  Future<JobMutationResultModel> confirmJob(String jobId) =>
      throw UnimplementedError();

  @override
  Future<JobMutationResultModel> createJob(CreateJobRequestModel request) =>
      throw UnimplementedError();

  @override
  Future<JobAgreementModel> getJobById(String jobId) =>
      throw UnimplementedError();

  @override
  Future<RoomJobsModel> getJobsByRoom(String roomId) =>
      throw UnimplementedError();

  @override
  Future<PaginatedResponse<JobAgreementModel>> getMyJobs({
    int page = 1,
    int limit = 10,
    JobStatus? status,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('Branding y widgets de calificación FRONT-09', () {
    testWidgets('BrandLogo muestra nombre oficial y eslogan verificado',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: BrandLogo(
                size: 48,
                showWordmark: true,
                showSlogan: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text(BrandLogo.appSlogan), findsOneWidget);
      expect(BrandLogo.appName, 'ManoLocal');
      expect(
        BrandLogo.appSlogan,
        'El oficio que necesitas, a la vuelta de tu calle.',
      );
    });

    testWidgets('StarRatingDisplay muestra estrellas, promedio y conteo',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                StarRatingDisplay(rating: 4.5, reviewCount: 12),
                StarRatingDisplay(rating: 0, reviewCount: 0, compact: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(12 reseñas)'), findsOneWidget);
      expect(find.text('Sin reseñas'), findsOneWidget);
    });

    test('ReviewsProvider carga páginas de reseñas y agrega nuevas reseñas en vivo',
        () async {
      final repo = _FakeReviewsRepository();
      final provider = ReviewsProvider(reviewsRepository: repo);

      final loaded = await provider.loadSpecialistReviews('esp-1', limit: 1);
      expect(loaded, isTrue);
      expect(provider.reviews.length, 1);
      expect(provider.hasMore, isTrue);

      await provider.loadMoreSpecialistReviews();
      expect(provider.reviews.length, 2);
      expect(provider.hasMore, isFalse);

      final result = await provider.submitReview(
        jobAgreementId: 'job-99',
        rating: 5,
        comment: 'Muy puntual',
      );
      expect(result, isNotNull);
      expect(provider.reviews.length, 3);
      expect(provider.specialistSummary?.ratingAverage, 4.9);
      expect(provider.specialistSummary?.ratingCount, 4);
    });

    testWidgets(
        'CreateReviewModal valida estrellas, envía POST /reviews y marca trabajo como calificado',
        (tester) async {
      final repo = _FakeReviewsRepository();
      final reviewsProvider = ReviewsProvider(reviewsRepository: repo);
      final jobsProvider = JobsProvider(jobsRepository: _StubJobsRepository());

      const completedJob = JobAgreementModel(
        id: 'job-completed-1',
        roomId: 'room-1',
        title: 'Mantenimiento eléctrico',
        feeAmount: 50,
        status: JobStatus.completed,
        room: JobRoomRefModel(
          id: 'room-1',
          employerId: 'emp-1',
          specialistId: 'esp-1',
        ),
      );
      jobsProvider.applySocketJobUpdate(completedJob);

      CreateReviewResultModel? modalResult;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ReviewsProvider>.value(
              value: reviewsProvider,
            ),
            ChangeNotifierProvider<JobsProvider>.value(value: jobsProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    modalResult = await CreateReviewModal.show(
                      context,
                      job: completedJob,
                      specialistName: 'Carlos López',
                    );
                  },
                  child: const Text('Abrir modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir modal'));
      await tester.pumpAndSettle();

      // Enviar sin seleccionar estrellas muestra validación local
      await tester.tap(find.text('Publicar reseña'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Selecciona una calificación de 1 a 5 estrellas antes de publicar.',
        ),
        findsOneWidget,
      );

      // Seleccionar 5 estrellas y escribir comentario
      await tester.tap(find.byKey(const ValueKey('star-input-5')));
      await tester.pump();
      expect(find.text('Excelente'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'Llegó a tiempo y dejó todo impecable.',
      );
      await tester.tap(find.text('Publicar reseña'));
      await tester.pumpAndSettle();

      expect(repo.lastSubmitted?.jobAgreementId, 'job-completed-1');
      expect(repo.lastSubmitted?.rating, 5);
      expect(
        repo.lastSubmitted?.comment,
        'Llegó a tiempo y dejó todo impecable.',
      );
      expect(modalResult?.specialistReputation.ratingAverage, 4.9);
      expect(jobsProvider.myJobs.single.hasReview, isTrue);
      expect(jobsProvider.myJobs.single.reviewRating, 5);
    });
  });
}
