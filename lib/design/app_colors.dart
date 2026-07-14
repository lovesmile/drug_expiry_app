import 'package:flutter/material.dart';
import 'palette.dart';


// Re-export so the public API of the design system is centralized
// at lib/design/app_colors.dart.  Consumers keep importing the same file
// they always have, but get a richer, layered set of tokens.
export 'palette.dart' show AppPalette;
export 'semantic_colors.dart' show AppSemanticColors, AppSemanticColorsX;
export 'app_theme.dart' show AppTheme;

/// ---------------------------------------------------------------------------
/// 兼容层 —— 历史 API 的薄封装。新代码 **必须** 走下面这套：
///
///   1. 主题相关色（背景/前景/边框/分割线）
///      → `Theme.of(context).colorScheme.{surface, onSurface,
///        onSurfaceVariant, outlineVariant, primary, error, ...}`
///      → 状态容器： `context.semantic.{statusValidContainer,
///        statusWarningContainer, statusExpiredContainer}`
///      → 系统 UI 风格：`AppTheme.systemUiOverlayStyle(brightness)`
///
///   2. 跨主题不变的品牌色 / 状态色
///      → `AppPalette.{brandGreen, statusValid, statusExpired, ...}`
///
///   3. 圆角 / 阴影 / 渐变
///      → `AppRadius.{card, small, medium, large, button, pill}`
///      → `AppShadows.{card(brightness), floating(brightness), glow(color)}`
///      → `AppGradients.{brandGreen, valid, warning, expired,
///        surfaceFor(brightness)}`
///
/// **不要在新建的代码里使用本类**。本类只用来让旧调用点先跑通，
/// 后续逐文件迁移完成即可删除。
/// ---------------------------------------------------------------------------
@Deprecated('Use Theme.of(context).colorScheme / context.semantic / '
    'AppPalette / AppRadius / AppShadows / AppGradients. '
    'AppColorsV2 is kept only as a compatibility shim.')
class AppColorsV2 {
  AppColorsV2._();

  // ---- 品牌色（跨主题不变） ----
  static const Color brandGreen = AppPalette.brandGreen;
  static const Color brandGreenLight = AppPalette.brandGreenLight;
  static const Color brandGreenDark = AppPalette.brandGreenDark;
  static const Color brandBlue = AppPalette.brandBlue;
  static const Color brandBlueLight = AppPalette.brandBlueLight;
  static const Color brandBlueDark = AppPalette.brandBlueDark;
  static const Color brandCyan = AppPalette.brandCyan;
  static const Color brandCyanLight = AppPalette.brandCyanLight;
  static const Color brandCyanDark = AppPalette.brandCyanDark;

  // ---- 状态色（跨主题不变） ----
  static const Color statusValid = AppPalette.statusValid;
  static const Color statusValidGradient = AppPalette.statusValidGradient;
  static const Color statusValidLight = AppPalette.statusValidLight;
  static const Color statusWarning = AppPalette.statusWarning;
  static const Color statusWarningGradient = AppPalette.statusWarningGradient;
  static const Color statusWarningLight = AppPalette.statusWarningLight;
  static const Color statusExpired = AppPalette.statusExpired;
  static const Color statusExpiredGradient = AppPalette.statusExpiredGradient;
  static const Color statusExpiredLight = AppPalette.statusExpiredLight;

  // ---- 主题相关色（const 兜底值，仅浅色模式正确；深色模式请走
  //   Theme.of(context).colorScheme）----
  // 这些是历史值，保留是为了让旧代码先编过；新代码绝不能直接 const 引用。
  static const Color bgMain = Color(0xFFFAFAFA);
  static const Color darkBgMain = Color(0xFF0F172A);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgElevated = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color divider = AppPalette.divider;
  static const Color shadow = AppPalette.shadow;
  static const Color overlay = AppPalette.overlay;
}

/// 渐变色集合 —— 设计系统的"色块"层。
class AppGradients {
  AppGradients._();

  static const LinearGradient brandGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.brandGreenLight, AppPalette.brandGreen],
  );
  static const LinearGradient brandBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.brandBlueLight, AppPalette.brandBlue],
  );
  static const LinearGradient brandCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.brandCyanLight, AppPalette.brandCyan],
  );
  static const LinearGradient valid = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.statusValidGradient, AppPalette.statusValid],
  );
  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.statusWarningGradient, AppPalette.statusWarning],
  );
  static const LinearGradient expired = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.statusExpiredGradient, AppPalette.statusExpired],
  );

  // 背景渐变（按 Brightness 切换）。
  static const LinearGradient _surfaceLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );
  static const LinearGradient _surfaceDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  /// 根据当前亮度返回对应的 surface 渐变。
  static LinearGradient surfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? _surfaceDark : _surfaceLight;

  /// 旧 API 兼容 —— 默认浅色。请改用 [surfaceFor]。
  static const LinearGradient surface = _surfaceLight;
  static const LinearGradient darkSurface = _surfaceDark;

  /// 根据状态串返回对应渐变。
  static LinearGradient fromStatus(String status) {
    switch (status) {
      case 'valid':
        return valid;
      case 'warning':
        return warning;
      case 'expired':
        return expired;
      default:
        return brandGreen;
    }
  }
}

/// 圆角系统 —— 所有命名圆角集中管理。
class AppRadius {
  AppRadius._();

  // 数值常量
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  // 新短名（推荐）
  static const BorderRadius xsRadius = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(full));

  // 旧名兼容（保持原行为）
  static const BorderRadius smallRadius = small;
  static const BorderRadius mediumRadius = medium;
  static const BorderRadius largeRadius = large;
  static const BorderRadius extraLargeRadius = extraLarge;
  static const BorderRadius cardRadius = card;
  static const BorderRadius buttonRadius = button;
  static const BorderRadius chipRadius = pill;
}

/// 阴影系统 —— 必须接受 Brightness，确保深色模式不出现脏阴影。
class AppShadows {
  AppShadows._();

  /// 卡片阴影：浅色下有 12px 模糊，深色下 0（surface 自带层级）。
  static List<BoxShadow> card(Brightness brightness) {
    if (brightness == Brightness.dark) return const <BoxShadow>[];
    return const [
      BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
    ];
  }

  /// 悬浮阴影：FAB / Dialog 用，深色下用更深一档。
  static List<BoxShadow> floating(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6)),
      ];
    }
    return const [
      BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 8)),
    ];
  }

  /// 颜色发光（用于主按钮/状态徽章的点缀），按亮度微调 alpha。
  static List<BoxShadow> glow(Color color, {Brightness? brightness}) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: color.withValues(alpha: isDark ? 0.32 : 0.40),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // 旧 API 兼容（默认浅色 + 默认 shadow 色）。
  static List<BoxShadow> cardLegacy() => card(Brightness.light);
  static List<BoxShadow> elevatedLegacy() => floating(Brightness.light);
}

/// 旧版 AppShadowsV2 别名（避免改调用点）。
@Deprecated('Use AppShadows.card(brightness) / AppShadows.floating(brightness) / '
    'AppShadows.glow(color, brightness: brightness).')
class AppShadowsV2 {
  AppShadowsV2._();

  static const BoxShadow sm = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 4,
    offset: Offset(0, 1),
  );
  static const BoxShadow md = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  static const BoxShadow lg = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
  static const BoxShadow xl = BoxShadow(
    color: Color(0x1E000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
  static const BoxShadow glow = BoxShadow(
    color: Color(0x4010B981),
    blurRadius: 20,
    offset: Offset(0, 4),
  );

  static List<BoxShadow> card({Color? color}) => [
        BoxShadow(
          color: (color ?? AppPalette.shadow).withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> elevated({Color? color}) => [
        BoxShadow(
          color: (color ?? AppPalette.shadow).withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}