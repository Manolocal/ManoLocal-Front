import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

/// Controla el tema visual (Claro / Oscuro) con persistencia local.
class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeProvider(this._prefs)
      : _themeMode = _parseMode(_prefs.getString(StorageKeys.themeMode));

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _prefs.setString(
      StorageKeys.themeMode,
      enabled ? 'dark' : 'light',
    );
  }

  static ThemeMode _parseMode(String? raw) {
    if (raw == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }
}
