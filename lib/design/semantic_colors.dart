import 'package:flutter/material.dart';

/// 语义色 —— 随主题切换的角色色扩展。
///
/// 为什么用 [ThemeExtension] 而不是 `AppColorsV2.darkBgMain`：
///   - 单一来源：所有主题相关颜色集中在 [buildAppTheme] 注入，
///     业务代码通过 `context.semantic.X` 取值，永远不会写出"浅色背景配深色文字"这种 bug。
///   - 跨主题：浅色模式的 valid 浅底是淡绿（#D1FAE5），深色模式必须是
///     对应的深绿（#064E3B），靠手工 if-else 切换必然遗漏，靠 ThemeExtension 自动跟随。
///   - 可动画：[lerp] 实现主题过渡动画。
///   - 可测试：可以从任意 [ThemeData] 取出断言。
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  /// 状态色"容器"背景（valid/warning/expired 的浅底/深底）
  /// 浅色模式是低饱和的浅色，深色模式是低饱和的深色。
  final Color statusValidContainer;
  final Color statusWarningContainer;
  final Color statusExpiredContainer;

  /// 状态色"在容器上"的文字色（与容器背景形成对比）
  final Color onStatusValidContainer;
  final Color onStatusWarningContainer;
  final Color onStatusExpiredContainer;

  /// 中性"骨架"色 —— 主题模式特有的辅助色，ColorScheme 没覆盖到。
  /// 例如：键盘硬件提取出的半透明遮罩、对话框分隔等。
  final Color scrim;
  final Color overlay;

  const AppSemanticColors({
    required this.statusValidContainer,
    required this.statusWarningContainer,
    required this.statusExpiredContainer,
    required this.onStatusValidContainer,
    required this.onStatusWarningContainer,
    required this.onStatusExpiredContainer,
    required this.scrim,
    required this.overlay,
  });

  @override
  AppSemanticColors copyWith({
    Color? statusValidContainer,
    Color? statusWarningContainer,
    Color? statusExpiredContainer,
    Color? onStatusValidContainer,
    Color? onStatusWarningContainer,
    Color? onStatusExpiredContainer,
    Color? scrim,
    Color? overlay,
  }) {
    return AppSemanticColors(
      statusValidContainer: statusValidContainer ?? this.statusValidContainer,
      statusWarningContainer: statusWarningContainer ?? this.statusWarningContainer,
      statusExpiredContainer: statusExpiredContainer ?? this.statusExpiredContainer,
      onStatusValidContainer: onStatusValidContainer ?? this.onStatusValidContainer,
      onStatusWarningContainer: onStatusWarningContainer ?? this.onStatusWarningContainer,
      onStatusExpiredContainer: onStatusExpiredContainer ?? this.onStatusExpiredContainer,
      scrim: scrim ?? this.scrim,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      statusValidContainer: Color.lerp(statusValidContainer, other.statusValidContainer, t)!,
      statusWarningContainer: Color.lerp(statusWarningContainer, other.statusWarningContainer, t)!,
      statusExpiredContainer: Color.lerp(statusExpiredContainer, other.statusExpiredContainer, t)!,
      onStatusValidContainer: Color.lerp(onStatusValidContainer, other.onStatusValidContainer, t)!,
      onStatusWarningContainer: Color.lerp(onStatusWarningContainer, other.onStatusWarningContainer, t)!,
      onStatusExpiredContainer: Color.lerp(onStatusExpiredContainer, other.onStatusExpiredContainer, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }

  // ====== 浅色模式 ======
  static const AppSemanticColors light = AppSemanticColors(
    // 状态容器：低饱和浅色
    statusValidContainer: Color(0xFFD1FAE5),   // 淡绿
    statusWarningContainer: Color(0xFFFEF3C7), // 淡琥珀
    statusExpiredContainer: Color(0xFFFEE2E2), // 淡红
    // 状态容器上的文字：使用对应的饱和主色
    onStatusValidContainer: Color(0xFF065F46),
    onStatusWarningContainer: Color(0xFF92400E),
    onStatusExpiredContainer: Color(0xFF991B1B),
    scrim: Color(0x52000000),
    overlay: Color(0x80000000),
  );

  // ====== 深色模式 ======
  static const AppSemanticColors dark = AppSemanticColors(
    // 状态容器：低饱和深色（与深色背景有层次但不过亮）
    statusValidContainer: Color(0xFF064E3B),   // 深绿
    statusWarningContainer: Color(0xFF78350F), // 深琥珀
    statusExpiredContainer: Color(0xFF7F1D1D), // 深红
    // 状态容器上的文字：使用对应的浅色
    onStatusValidContainer: Color(0xFFA7F3D0),
    onStatusWarningContainer: Color(0xFFFDE68A),
    onStatusExpiredContainer: Color(0xFFFECACA),
    scrim: Color(0x99000000),
    overlay: Color(0xA6000000),
  );
}

/// UI 代码用这个扩展取语义色，语义更清晰，IDE 自动补全更好。
///
/// 示例：
/// ```dart
/// final color = context.semantic.statusValidContainer;
/// ```
extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
