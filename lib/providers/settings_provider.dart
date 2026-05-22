import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_settings.dart';
import '../services/database_service.dart';
import '../constants.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  ReminderSettings? _settings;
  bool _isLoading = false;
  bool _isDarkMode = false;
  bool _darkModeFollowSystem = false;
  bool _appLockEnabled = false;
  String _themeColor = AppTheme.green;

  ReminderSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  bool get darkModeFollowSystem => _darkModeFollowSystem;
  bool get appLockEnabled => _appLockEnabled;
  String get themeColor => _themeColor;

  Color get seedColor => AppTheme.seeds[_themeColor] ?? AppTheme.seeds[AppTheme.green]!;
  Color get lightTint => AppTheme.lightTints[_themeColor] ?? AppTheme.lightTints[AppTheme.green]!;

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
    _isDarkMode = prefs.getBool(AppStrings.darkModeKey) ?? false;
    _darkModeFollowSystem = prefs.getBool(AppStrings.darkModeFollowSystemKey) ?? false;
    _appLockEnabled = prefs.getBool(AppStrings.appLockKey) ?? false;
    _themeColor = prefs.getString(AppStrings.themeColorKey) ?? AppTheme.green;

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
    await prefs.setBool(AppStrings.darkModeKey, value);
    await prefs.setBool(AppStrings.darkModeFollowSystemKey, _darkModeFollowSystem);
    notifyListeners();
  }

  Future<void> setDarkModeFollowSystem(bool value) async {
    _darkModeFollowSystem = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppStrings.darkModeFollowSystemKey, value);
    notifyListeners();
  }

  Future<void> setThemeColor(String value) async {
    _themeColor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppStrings.themeColorKey, value);
    notifyListeners();
  }

  Future<void> setAppLockEnabled(bool value) async {
    _appLockEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppStrings.appLockKey, value);
    notifyListeners();
  }
}
