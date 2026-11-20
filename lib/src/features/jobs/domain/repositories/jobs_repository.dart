import '../../../../core/enums/backend_enums.dart';
import '../../../../core/models/paginated_response.dart';
import '../models/job_models.dart';

/// Contrato de repositorio para acuerdos de trabajo y ciclo de cuota ($50 MXN).
abstract class JobsRepository {
  Future<JobMutationResultModel> createJob(CreateJobRequestModel request);

  Future<PaginatedResponse<JobAgreementModel>> getMyJobs({
    int page = 1,
    int limit = 10,
    JobStatus? status,
  });

  Future<RoomJobsModel> getJobsByRoom(String roomId);

  Future<JobAgreementModel> getJobById(String jobId);

  Future<JobMutationResultModel> confirmJob(String jobId);

  Future<JobMutationResultModel> completeJob(String jobId);

  Future<JobMutationResultModel> cancelJob(String jobId, {String? reason});
}
