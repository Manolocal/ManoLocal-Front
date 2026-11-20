import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

/// Contrato para el almacenamiento local del token JWT y sesión.
abstract class TokenStorageService {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
  Future<void> clearAll();
}

class SharedPreferencesTokenStorage implements TokenStorageService {
  final SharedPreferences _prefs;

  SharedPreferencesTokenStorage(this._prefs);

  @override
  Future<String?> getToken() async {
    return _prefs.getString(StorageKeys.accessToken);
  }

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(StorageKeys.accessToken, token);
  }

  @override
  Future<void> clearToken() async {
    await _prefs.remove(StorageKeys.accessToken);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(StorageKeys.accessToken);
    await _prefs.remove(StorageKeys.cachedUser);
    await _prefs.remove(StorageKeys.pendingTwoFactorEmail);
  }
}
