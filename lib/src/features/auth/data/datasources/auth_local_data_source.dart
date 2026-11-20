import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/services/token_storage_service.dart';
import '../../domain/models/auth_models.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> saveUser(AuthUserModel user);
  Future<AuthUserModel?> getUser();
  Future<void> savePendingTwoFactorEmail(String email);
  Future<String?> getPendingTwoFactorEmail();
  Future<void> clearPendingTwoFactorEmail();
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final TokenStorageService tokenStorage;
  final SharedPreferences prefs;

  AuthLocalDataSourceImpl({
    required this.tokenStorage,
    required this.prefs,
  });

  @override
  Future<void> saveToken(String token) => tokenStorage.saveToken(token);

  @override
  Future<String?> getToken() => tokenStorage.getToken();

  @override
  Future<void> saveUser(AuthUserModel user) async {
    await prefs.setString(StorageKeys.cachedUser, jsonEncode(user.toJson()));
  }

  @override
  Future<AuthUserModel?> getUser() async {
    final raw = prefs.getString(StorageKeys.cachedUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AuthUserModel.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePendingTwoFactorEmail(String email) async {
    await prefs.setString(StorageKeys.pendingTwoFactorEmail, email);
  }

  @override
  Future<String?> getPendingTwoFactorEmail() async {
    return prefs.getString(StorageKeys.pendingTwoFactorEmail);
  }

  @override
  Future<void> clearPendingTwoFactorEmail() async {
    await prefs.remove(StorageKeys.pendingTwoFactorEmail);
  }

  @override
  Future<void> clear() => tokenStorage.clearAll();
}
