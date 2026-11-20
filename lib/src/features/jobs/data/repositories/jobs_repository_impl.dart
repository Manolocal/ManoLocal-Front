import '../../../../core/enums/backend_enums.dart';
import '../../../../core/models/paginated_response.dart';
import '../../domain/models/job_models.dart';
import '../../domain/repositories/jobs_repository.dart';
import '../datasources/jobs_remote_data_source.dart';

class JobsRepositoryImpl implements JobsRepository {
  final JobsRemoteDataSource remoteDataSource;

  JobsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<JobMutationResultModel> createJob(CreateJobRequestModel request) {
    return remoteDataSource.createJob(request);
  }

  @override
  Future<PaginatedResponse<JobAgreementModel>> getMyJobs({
    int page = 1,
    int limit = 10,
    JobStatus? status,
  }) {
    return remoteDataSource.getMyJobs(
      page: page,
      limit: limit,
      status: status,
    );
  }

  @override
  Future<RoomJobsModel> getJobsByRoom(String roomId) {
    return remoteDataSource.getJobsByRoom(roomId);
  }

  @override
  Future<JobAgreementModel> getJobById(String jobId) {
    return remoteDataSource.getJobById(jobId);
  }

  @override
  Future<JobMutationResultModel> confirmJob(String jobId) {
    return remoteDataSource.confirmJob(jobId);
  }

  @override
  Future<JobMutationResultModel> completeJob(String jobId) {
    return remoteDataSource.completeJob(jobId);
  }

  @override
  Future<JobMutationResultModel> cancelJob(String jobId, {String? reason}) {
    return remoteDataSource.cancelJob(jobId, reason: reason);
  }
}
