import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

abstract class TokenStorageService {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<String?> getRefreshToken();
  Future<void> saveRefreshToken(String token);
  Future<void> clearAll();
}

class SharedPreferencesTokenStorage implements TokenStorageService {
  final SharedPreferences _prefs;

  SharedPreferencesTokenStorage(this._prefs);

  @override
  Future<String?> getToken() async {
    return _prefs.getString(ApiConstants.tokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(ApiConstants.tokenKey, token);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _prefs.getString(ApiConstants.refreshTokenKey);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(ApiConstants.refreshTokenKey, token);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(ApiConstants.tokenKey);
    await _prefs.remove(ApiConstants.refreshTokenKey);
    await _prefs.remove(ApiConstants.userKey);
  }
}
