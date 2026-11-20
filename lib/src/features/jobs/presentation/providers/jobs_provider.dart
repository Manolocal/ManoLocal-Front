import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/job_models.dart';
import '../../domain/repositories/jobs_repository.dart';

/// Resultado enriquecido de una mutación de trabajo para detectar HTTP 402 (saldo insuficiente).
class JobActionOutcome {
  final JobMutationResultModel? result;
  final InsufficientBalanceException? insufficientBalance;
  final String? errorMessage;

  const JobActionOutcome({
    this.result,
    this.insufficientBalance,
    this.errorMessage,
  });

  bool get isSuccess => result != null;
  bool get isInsufficientBalance => insufficientBalance != null;
}

/// Provider para los acuerdos de trabajo (`/jobs`) y el estado activo por sala de chat.
class JobsProvider extends ChangeNotifier {
  final JobsRepository jobsRepository;

  List<JobAgreementModel> _myJobs = const [];
  PaginationMeta? _meta;
  JobStatus? _selectedStatus;

  final Map<String, RoomJobsModel> _roomJobsCache = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isMutating = false;
  String? _errorMessage;

  JobsProvider({required this.jobsRepository});

  List<JobAgreementModel> get myJobs => _myJobs;
  PaginationMeta? get meta => _meta;
  JobStatus? get selectedStatus => _selectedStatus;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isMutating => _isMutating;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _meta?.hasNext ?? false;

  RoomJobsModel? roomJobs(String roomId) => _roomJobsCache[roomId];

  Future<bool> loadMyJobs({JobStatus? status}) async {
    _selectedStatus = status;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await jobsRepository.getMyJobs(
        page: 1,
        limit: 15,
        status: _selectedStatus,
      );
      _myJobs = response.items;
      _meta = response.meta;
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

  Future<void> loadMoreJobs() async {
    if (_isLoadingMore || !hasMore) return;
    final nextPage = (_meta?.page ?? 1) + 1;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await jobsRepository.getMyJobs(
        page: nextPage,
        limit: _meta?.limit ?? 15,
        status: _selectedStatus,
      );
      _myJobs = [..._myJobs, ...response.items];
      _meta = response.meta;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<RoomJobsModel?> loadRoomJobs(String roomId) async {
    try {
      final data = await jobsRepository.getJobsByRoom(roomId);
      _roomJobsCache[roomId] = data;
      notifyListeners();
      return data;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<JobActionOutcome> createJob(CreateJobRequestModel request) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await jobsRepository.createJob(request);
      _upsertJobLocally(result.job);
      _isMutating = false;
      notifyListeners();
      return JobActionOutcome(result: result);
    } catch (e) {
      return _handleMutationError(e);
    }
  }

  Future<JobActionOutcome> confirmJob(String jobId) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await jobsRepository.confirmJob(jobId);
      _upsertJobLocally(result.job);
      _isMutating = false;
      notifyListeners();
      return JobActionOutcome(result: result);
    } catch (e) {
      return _handleMutationError(e);
    }
  }

  Future<JobActionOutcome> completeJob(String jobId) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await jobsRepository.completeJob(jobId);
      _upsertJobLocally(result.job);
      _isMutating = false;
      notifyListeners();
      return JobActionOutcome(result: result);
    } catch (e) {
      return _handleMutationError(e);
    }
  }

  Future<JobActionOutcome> cancelJob(String jobId, {String? reason}) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await jobsRepository.cancelJob(jobId, reason: reason);
      _upsertJobLocally(result.job);
      _isMutating = false;
      notifyListeners();
      return JobActionOutcome(result: result);
    } catch (e) {
      return _handleMutationError(e);
    }
  }

  /// Aplica una actualización de trabajo recibida en vivo desde Socket.IO.
  void applySocketJobUpdate(JobAgreementModel job) {
    _upsertJobLocally(job);
    notifyListeners();
  }

  /// Marca localmente un acuerdo finalizado como reseñado tras publicar en `/reviews`.
  void markJobReviewed(String jobId, int rating) {
    JobAgreementModel? target;
    for (final j in _myJobs) {
      if (j.id == jobId) {
        target = j;
        break;
      }
    }
    if (target == null) {
      for (final room in _roomJobsCache.values) {
        for (final j in room.jobs) {
          if (j.id == jobId) {
            target = j;
            break;
          }
        }
        if (target != null) break;
      }
    }
    if (target == null) return;

    _upsertJobLocally(
      target.copyWith(hasReview: true, reviewRating: rating),
    );
    notifyListeners();
  }

  void _upsertJobLocally(JobAgreementModel updated) {
    // Actualizar lista global
    final idx = _myJobs.indexWhere((j) => j.id == updated.id);
    if (idx >= 0) {
      final copy = [..._myJobs];
      copy[idx] = updated;
      _myJobs = _selectedStatus == null
          ? copy
          : copy.where((j) => j.status == _selectedStatus).toList();
    } else if (_selectedStatus == null || updated.status == _selectedStatus) {
      _myJobs = [updated, ..._myJobs];
    }

    // Actualizar caché de la sala
    final existing = _roomJobsCache[updated.roomId];
    final currentList = existing?.jobs ?? const <JobAgreementModel>[];
    final roomIdx = currentList.indexWhere((j) => j.id == updated.id);
    final nextList = [...currentList];
    if (roomIdx >= 0) {
      nextList[roomIdx] = updated;
    } else {
      nextList.insert(0, updated);
    }

    JobAgreementModel? active;
    for (final item in nextList) {
      if (item.status == JobStatus.pending ||
          item.status == JobStatus.confirmed) {
        active = item;
        break;
      }
    }

    _roomJobsCache[updated.roomId] = RoomJobsModel(
      roomId: updated.roomId,
      activeJob: active,
      jobs: nextList,
    );
  }

  JobActionOutcome _handleMutationError(Object error) {
    _isMutating = false;
    InsufficientBalanceException? insufficient;
    if (error is DioException && error.error is InsufficientBalanceException) {
      insufficient = error.error as InsufficientBalanceException;
    } else if (error is InsufficientBalanceException) {
      insufficient = error;
    }

    final msg = _extractErrorMessage(error);
    _errorMessage = msg;
    notifyListeners();
    return JobActionOutcome(
      insufficientBalance: insufficient,
      errorMessage: msg,
    );
  }

  void clear() {
    _myJobs = const [];
    _meta = null;
    _selectedStatus = null;
    _roomJobsCache.clear();
    _errorMessage = null;
    _isLoading = false;
    _isLoadingMore = false;
    _isMutating = false;
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
