import 'package:flutter/material.dart';

/// 设计系统调色板 —— 跨主题不变的语义色。
///
/// 设计原则：颜色分两种角色。
///   1. 跨主题不变的品牌色 / 状态色（valid=绿, expired=红），它们表达"含义"，
///      进 [AppPalette]，永远 const。
///   2. 随主题切换的"角色色"（背景/文字/边框），它们表达"容器/前景"关系，
///      应通过 `Theme.of(context).colorScheme` 取，参考 [ColorScheme] 设计。
///
/// 状态色容器（valid 浅底、warning 浅底、expired 浅底）会随主题切换而变化，
/// 因为"浅底"在深色模式下应该是对应的深色版本，参考 [AppSemanticColors]。
class AppPalette {
  AppPalette._();

  // ====== 品牌色（品牌资产，跨模式不变） ======
  static const Color brandGreen = Color(0xFF10B981);
  static const Color brandGreenLight = Color(0xFF34D399);
  static const Color brandGreenDark = Color(0xFF059669);

  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color brandBlueLight = Color(0xFF60A5FA);
  static const Color brandBlueDark = Color(0xFF2563EB);

  static const Color brandCyan = Color(0xFF06B6D4);
  static const Color brandCyanLight = Color(0xFF22D3EE);
  static const Color brandCyanDark = Color(0xFF0891B2);

  // ====== 状态色（valid/warning/expired 的"本体"，跨模式不变） ======
  /// 有效 —— 翠绿
  static const Color statusValid = Color(0xFF10B981);
  static const Color statusValidGradient = Color(0xFF34D399);

  /// 有效 —— 浅绿底纹（valid 状态容器下的浅色）。
  /// 注意：作为跨主题色，**不要在深色模式下使用**。
  /// 深色模式下请使用 `context.semantic.statusValidContainer`（自适应深浅）。
  static const Color statusValidLight = Color(0xFFD1FAE5);

  /// 即将过期 —— 琥珀
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusWarningGradient = Color(0xFFFBBF24);

  /// 即将过期 —— 浅琥珀底纹（warning 状态容器下的浅色）。
  /// 注意：作为跨主题色，**不要在深色模式下使用**。
  /// 深色模式下请使用 `context.semantic.statusWarningContainer`。
  static const Color statusWarningLight = Color(0xFFFEF3C7);

  /// 已过期 / 危险 —— 红色
  static const Color statusExpired = Color(0xFFEF4444);
  static const Color statusExpiredGradient = Color(0xFFF87171);

  /// 已过期 / 危险 —— 浅红底纹（expired 状态容器下的浅色）。
  /// 注意：作为跨主题色，**不要在深色模式下使用**。
  /// 深色模式下请使用 `context.semantic.statusExpiredContainer`。
  static const Color statusExpiredLight = Color(0xFFFEE2E2);

  /// 把 [ItemStatus] / [WarrantyStatus] 映射到对应的主色。
  /// 跨主题不变（valid=绿/warning=琥珀/expired=红），含义优先于"主题跟随"——
  /// 无论深浅模式，valid 都应该是绿色。
  ///
  /// 用 enum name 比对，避免在 palette 里 import models 形成循环依赖。
  /// 不传任何 enum 也不会崩，找不到就回退到 valid。
  static Color colorOf(Object status) {
    final s = status.toString().split('.').last;
    switch (s) {
      case 'valid':
        return statusValid;
      case 'warning':
        return statusWarning;
      case 'expired':
        return statusExpired;
      case 'none':
        return const Color(0xFF64748B);
    }
    return statusValid;
  }

  // ====== 主题种子色（用户在设置中切换） ======
  static const Map<String, Color> themeSeeds = {
    'green': brandGreen,
    'blue': brandBlue,
    'cyan': brandCyan,
  };

  // ====== 辅助通用色（跨主题不变，但不是"状态容器"背景）：========
  /// 分割线色。
  /// 浅色模式下应使用 `colorScheme.outlineVariant`（更准），这里保留为兜底。
  static const Color divider = Color(0xFFE2E8F0);

  /// 黑色半透明（用于阴影，浅色模式下有效，深色模式下基本不可见）。
  static const Color shadow = Color(0x1A000000);

  /// 蒙层色（用于 dialog 背后的遮罩）。
  static const Color overlay = Color(0x80000000);
}
