import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_settings.dart';
import '../services/database_service.dart';
import '../constants.dart' as const_alias;

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  ReminderSettings? _settings;
  bool _isLoading = false;
  bool _isDarkMode = false;
  bool _darkModeFollowSystem = false;
  bool _appLockEnabled = false;
  String _themeColor = const_alias.AppTheme.green;

  ReminderSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  bool get darkModeFollowSystem => _darkModeFollowSystem;
  bool get appLockEnabled => _appLockEnabled;
  String get themeColor => _themeColor;

  Color get seedColor => const_alias.AppTheme.seeds[_themeColor] ?? const_alias.AppTheme.seeds[const_alias.AppTheme.green]!;
  Color get lightTint => const_alias.AppTheme.lightTints[_themeColor] ?? const_alias.AppTheme.lightTints[const_alias.AppTheme.green]!;

  ThemeMode get themeMode {
    if (_darkModeFollowSystem) return ThemeMode.system;
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _db.getReminderSettings();
    } catch (_) {
      _settings = null;
    }

    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(const_alias.AppStrings.darkModeKey) ?? false;
    _darkModeFollowSystem = prefs.getBool(const_alias.AppStrings.darkModeFollowSystemKey) ?? false;
    _appLockEnabled = prefs.getBool(const_alias.AppStrings.appLockKey) ?? false;
    _themeColor = prefs.getString(const_alias.AppStrings.themeColorKey) ?? const_alias.AppTheme.green;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSettings(ReminderSettings settings) async {
    await _db.saveReminderSettings(settings);
    _settings = settings;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    if (value) _darkModeFollowSystem = false; // on → off system follow
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(const_alias.AppStrings.darkModeKey, value);
    await prefs.setBool(const_alias.AppStrings.darkModeFollowSystemKey, _darkModeFollowSystem);
    notifyListeners();
  }

  Future<void> setDarkModeFollowSystem(bool value) async {
    _darkModeFollowSystem = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(const_alias.AppStrings.darkModeFollowSystemKey, value);
    notifyListeners();
  }

  Future<void> setThemeColor(String value) async {
    _themeColor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(const_alias.AppStrings.themeColorKey, value);
    notifyListeners();
  }

  Future<void> setAppLockEnabled(bool value) async {
    _appLockEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(const_alias.AppStrings.appLockKey, value);
    notifyListeners();
  }
}
