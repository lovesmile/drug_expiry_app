import 'package:flutter/material.dart';

class AppColors {
  static const Color brandPrimary = Color(0xFF4CAF50);
  static const Color brandPrimaryVariant = Color(0xFF388E3C);
  static const Color brandSecondary = Color(0xFFE8F5E9);
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusWarning = Color(0xFFFF9800);
  static const Color statusError = Color(0xFFF44336);
  static const Color statusInfo = Color(0xFF2196F3);
  static const Color bgMain = Color(0xFFF0F4F0);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textBody = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Dark mode
  static const Color darkBgMain = Color(0xFF121212);
  static const Color darkBgSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextBody = Color(0xFFBDBDBD);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkDivider = Color(0xFF333333);
  static const Color darkCard = Color(0xFF2C2C2C);
}

class AppSizes {
  static const double phoneWidth = 375;
  static const double appBarHeight = 56;
  static const double bottomNavHeight = 56;
  static const double cardRadius = 12;
  static const double buttonRadius = 12;
  static const double inputRadius = 8;
  static const double fabSize = 56;
  static const double iconSize = 24;
  static const double touchTarget = 48;
}

class AppShadows {
  static const BoxShadow card = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  static const BoxShadow nav = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.06),
    blurRadius: 6,
    offset: Offset(0, -1),
  );
  static const BoxShadow fab = BoxShadow(
    color: Color.fromRGBO(76, 175, 80, 0.4),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
}

class AppTheme {
  static const String green = 'green';
  static const String blue = 'blue';
  static const String cyan = 'cyan';

  static const Map<String, Color> seeds = {
    green: Color(0xFF4CAF50),
    blue: Color(0xFF2196F3),
    cyan: Color(0xFF00BCD4),
  };

  static const Map<String, Color> lightTints = {
    green: Color(0xFFE8F5E9),
    blue: Color(0xFFE3F2FD),
    cyan: Color(0xFFE0F7FA),
  };

  static const List<String> options = [green, blue, cyan];

  static const Map<String, String> labels = {
    green: '绿色',
    blue: '蓝色',
    cyan: '青色',
  };

  static const Map<String, String> labelKeys = {
    green: 'theme_green',
    blue: 'theme_blue',
    cyan: 'theme_cyan',
  };
}

class AppStrings {
  static const String appName = '到期管家';
  static const String dbName = 'expiry_tracker.db';
  static const String drugsTable = 'drugs';
  static const String usersTable = 'users';
  static const String remindersTable = 'reminders';
  static const String familyTable = 'family_members';
  static const String barcodeCacheTable = 'barcode_cache';
  static const String settingsKey = 'app_settings';
  static const String darkModeKey = 'dark_mode';
  static const String darkModeFollowSystemKey = 'dark_mode_follow_system';
  static const String themeColorKey = 'theme_color';
  static const String appLockKey = 'app_lock_enabled';
  static const String sortByKey = 'sort_by';
  static const String sortAscKey = 'sort_asc';
}
