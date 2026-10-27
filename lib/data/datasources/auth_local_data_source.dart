import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/token_storage_service.dart';
import '../../domain/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
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
  Future<void> saveToken(String token) async {
    await tokenStorage.saveToken(token);
  }

  @override
  Future<String?> getToken() async {
    return tokenStorage.getToken();
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await prefs.setString(ApiConstants.userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel?> getUser() async {
    final rawUser = prefs.getString(ApiConstants.userKey);
    if (rawUser == null) return null;
    try {
      final json = jsonDecode(rawUser) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    await tokenStorage.clearAll();
  }
}
