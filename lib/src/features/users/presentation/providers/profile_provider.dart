import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/user_profile_models.dart';
import '../../domain/repositories/users_repository.dart';

/// Provider para el estado del perfil completo (`/users/me`) del usuario autenticado.
class ProfileProvider extends ChangeNotifier {
  final UsersRepository usersRepository;

  UserMeModel? _userMe;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileProvider({required this.usersRepository});

  UserMeModel? get userMe => _userMe;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userMe = await usersRepository.updateProfile(request);
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

  Future<bool> updateKnowledge(List<String> knowledges) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await usersRepository.updateKnowledge(knowledges);
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

  void clear() {
    _userMe = null;
    _errorMessage = null;
    _isLoading = false;
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
