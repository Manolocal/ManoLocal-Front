import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/user_profile_models.dart';
import '../../domain/repositories/users_repository.dart';

/// Provider para el estado del perfil completo (`/users/me`) del usuario autenticado.
class ProfileProvider extends ChangeNotifier {
  final UsersRepository usersRepository;

  UserMeModel? _userMe;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  ProfileProvider({required this.usersRepository});

  UserMeModel? get userMe => _userMe;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool get isPersonalDataComplete {
    final p = _userMe?.profile;
    if (p == null) return false;
    return (p.fullName?.trim().isNotEmpty ?? false) &&
        (p.phone?.trim().isNotEmpty ?? false) &&
        (p.address?.trim().isNotEmpty ?? false) &&
        (p.postalCode?.trim().isNotEmpty ?? false);
  }

  bool get isKycComplete {
    final p = _userMe?.profile;
    if (p == null) return false;
    return (p.ineUrl?.trim().isNotEmpty ?? false) &&
        (p.selfieUrl?.trim().isNotEmpty ?? false);
  }

  bool get isKnowledgeComplete {
    final user = _userMe;
    if (user == null) return false;
    if (user.role != UserRole.especialista) return true;
    return user.knowledges.isNotEmpty;
  }

  double get completionProgress {
    final user = _userMe;
    if (user == null) return 0;
    final totalSteps = user.role == UserRole.especialista ? 3 : 2;
    var completed = 0;
    if (isPersonalDataComplete) completed++;
    if (isKycComplete) completed++;
    if (user.role == UserRole.especialista && isKnowledgeComplete) completed++;
    return completed / totalSteps;
  }

  Future<bool> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userMe = await usersRepository.getMe();
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

  Future<bool> updateProfile(UpdateProfileRequestModel request) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userMe = await usersRepository.updateProfile(request);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateKnowledge(List<String> knowledges) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await usersRepository.updateKnowledge(knowledges);
      _userMe = await usersRepository.getMe();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _userMe = null;
    _errorMessage = null;
    _isLoading = false;
    _isSaving = false;
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
