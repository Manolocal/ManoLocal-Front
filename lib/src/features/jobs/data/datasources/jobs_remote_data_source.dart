import '../../../../core/constants/api_constants.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/job_models.dart';

abstract class JobsRemoteDataSource {
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

class JobsRemoteDataSourceImpl implements JobsRemoteDataSource {
  final ApiClient apiClient;

  JobsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<JobMutationResultModel> createJob(CreateJobRequestModel request) async {
    final response = await apiClient.post(
      ApiConstants.jobs,
      data: request.toJson(),
    );
    return _parseMutationResult(response.data, ApiConstants.jobs);
  }

  @override
  Future<PaginatedResponse<JobAgreementModel>> getMyJobs({
    int page = 1,
    int limit = 10,
    JobStatus? status,
  }) async {
    final response = await apiClient.get(
      ApiConstants.jobsMe,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.value,
      },
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return PaginatedResponse<JobAgreementModel>.fromJson(
        payload,
        JobAgreementModel.fromJson,
      );
    }
    throw FormatException('Respuesta inválida en /jobs/me: $payload');
  }

  @override
  Future<RoomJobsModel> getJobsByRoom(String roomId) async {
    final response = await apiClient.get(ApiConstants.jobsByRoom(roomId));
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return RoomJobsModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /jobs/room/$roomId: $payload');
  }

  @override
  Future<JobAgreementModel> getJobById(String jobId) async {
    final response = await apiClient.get(ApiConstants.jobById(jobId));
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return JobAgreementModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /jobs/$jobId: $payload');
  }

  @override
  Future<JobMutationResultModel> confirmJob(String jobId) async {
    final endpoint = ApiConstants.jobConfirm(jobId);
    final response = await apiClient.patch(endpoint);
    return _parseMutationResult(response.data, endpoint);
  }

  @override
  Future<JobMutationResultModel> completeJob(String jobId) async {
    final endpoint = ApiConstants.jobComplete(jobId);
    final response = await apiClient.patch(endpoint);
    return _parseMutationResult(response.data, endpoint);
  }

  @override
  Future<JobMutationResultModel> cancelJob(
    String jobId, {
    String? reason,
  }) async {
    final endpoint = ApiConstants.jobCancel(jobId);
    final response = await apiClient.patch(
      endpoint,
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return _parseMutationResult(response.data, endpoint);
  }

  JobMutationResultModel _parseMutationResult(
    dynamic rawResponse,
    String endpoint,
  ) {
    final payload = ApiClient.unwrapData(rawResponse);
    if (payload is Map<String, dynamic>) {
      return JobMutationResultModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en $endpoint: $payload');
  }
}
