import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../ai/domain/models/ai_models.dart';
import '../../../ai/domain/repositories/ai_repository.dart';

/// Provider de diagnóstico para validar conexión base con ManoLocal-Back (`GET /` y `GET /ai/status`).
class DashboardProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final AiRepository aiRepository;

  bool _isChecking = false;
  bool? _isBackendReachable;
  String? _healthMessage;
  AiStatusModel? _aiStatus;
  String? _lastError;
  DateTime? _lastCheckedAt;

  DashboardProvider({
    required this.apiClient,
    required this.aiRepository,
  });

  bool get isChecking => _isChecking;
  bool? get isBackendReachable => _isBackendReachable;
  String? get healthMessage => _healthMessage;
  AiStatusModel? get aiStatus => _aiStatus;
  String? get lastError => _lastError;
  DateTime? get lastCheckedAt => _lastCheckedAt;

  Future<void> checkBackendHealth() async {
    _isChecking = true;
    _lastError = null;
    notifyListeners();

    try {
      final healthResponse = await apiClient.get(
        ApiConstants.health,
        options: Options(extra: const {'requiresAuth': false}),
      );
      final unwrapped = ApiClient.unwrapData(healthResponse.data);
      _healthMessage = unwrapped?.toString() ?? 'API en línea';
      _isBackendReachable = true;

      try {
        _aiStatus = await aiRepository.getStatus();
      } catch (_) {
        // El health check principal ya fue exitoso aunque /ai/status falle.
      }
    } catch (e) {
      _isBackendReachable = false;
      _healthMessage = null;
      _lastError = _extractErrorMessage(e);
    } finally {
      _lastCheckedAt = DateTime.now();
      _isChecking = false;
      notifyListeners();
    }
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
