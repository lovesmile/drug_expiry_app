# 迁移规范（Migration Spec）—— UI 重构

## 项目背景
- 路径：`C:\Users\10385\Projects\drug_expiry_app`
- 平台：Flutter (Dart)
- 当前阶段：从旧的 `AppColorsV2` 平铺式 const 调色板 → 四层设计系统

## 四层架构（已经完成，不需要再改）
1. **`AppPalette`**（`lib/design/palette.dart`）：跨主题不变的品牌色 / 状态色
2. **`AppSemanticColors` + `context.semantic` 扩展**（`lib/design/semantic_colors.dart`）：随主题切换的状态容器色（`statusValidContainer` 等）
3. **`AppTheme.build(brightness, seed)` + `AppTheme.systemUiOverlayStyle(brightness)`**（`lib/design/app_theme.dart`）：ThemeData 工厂 + 系统 UI 风格
4. **`AppColorsV2` 兼容层**（`lib/design/app_colors.dart`）：**已标 @Deprecated**，保留 const 别名让旧代码先编过，**新代码禁止使用**

## 颜色映射规则（业务代码统一遵守）

### 主题相关色（容器/前景关系）
| 旧 token | 新 API |
|---|---|
| `AppColorsV2.bgMain` / `darkBgMain` | `Theme.of(context).colorScheme.surface` |
| `AppColorsV2.bgSurface` | `Theme.of(context).colorScheme.surface` |
| `AppColorsV2.bgElevated` | `Theme.of(context).colorScheme.surfaceContainerHighest` |
| `AppColorsV2.textPrimary` | `Theme.of(context).colorScheme.onSurface` |
| `AppColorsV2.textSecondary` | `Theme.of(context).colorScheme.onSurfaceVariant` |
| `AppColorsV2.textTertiary` / `textDisabled` | `Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)` |
| `AppColorsV2.borderLight` / `divider` | `Theme.of(context).colorScheme.outlineVariant` |

### 状态色（valid/warning/expired 主体色，跨主题不变）
| 旧 token | 新 API |
|---|---|
| `AppColorsV2.statusValid` | `AppPalette.statusValid` |
| `AppColorsV2.statusWarning` | `AppPalette.statusWarning` |
| `AppColorsV2.statusExpired` | `AppPalette.statusExpired` |

### 状态色容器（浅底/深底，会随主题切换）
| 旧 token | 新 API |
|---|---|
| `AppColorsV2.statusValidLight` | `context.semantic.statusValidContainer` |
| `AppColorsV2.statusWarningLight` | `context.semantic.statusWarningContainer` |
| `AppColorsV2.statusExpiredLight` | `context.semantic.statusExpiredContainer` |
| 容器上的文字（如过期按钮文字） | `context.semantic.onStatusExpiredContainer` 等 |

### 品牌色（按业务意图选）
- **如果想让元素跟随用户的"主题色"设置** → `Theme.of(context).colorScheme.primary`
- **如果想始终是绿色（品牌主色）** → `AppPalette.brandGreen`

## 圆角 / 阴影 / 渐变
| 旧 | 新 |
|---|---|
| `AppShadowsV2.card()` | `AppShadows.card(Theme.of(context).brightness)` |
| `AppShadowsV2.elevated()` | `AppShadows.floating(Theme.of(context).brightness)` |
| `AppRadius.largeRadius` / `cardRadius` | `AppRadius.large` / `AppRadius.card` |
| `AppRadius.buttonRadius` | `AppRadius.button` |
| `AppRadius.mediumRadius` | `AppRadius.medium` |
| `AppGradients.surface`（直接用浅色） | `AppGradients.surfaceFor(Theme.of(context).brightness)` |

## 约束（业务代码不允许做的事）
1. **业务代码不直接 `const Color(0xFF...)` 写死颜色**（除 splash 等纯品牌展示页）
2. **不用 `withOpacity`，全部用 `withValues(alpha: x)`**
3. **不在 `Theme.of(context)` 上下文里写 `const`**（如 `const Text(style: TextStyle(color: Theme.of(context).colorScheme.onSurface))` 会编译失败）
4. **需要 `BuildContext` 取色时，在 build 方法内取，然后塞进 widget**
5. **卡片 / Surface 一律用 `Theme.of(context).cardTheme` / `colorScheme.surfaceContainerLow`**，不要再 `BoxDecoration(color: ...)` 写死

## 验收标准
- `flutter analyze`：0 error 0 warning
- `grep -rE "Color\(0x" lib/screens lib/widgets` 应该只剩空匹配（业务代码 0 处硬编码）
- `grep -r "AppColorsV2\." lib/screens lib/widgets` 应该只剩空匹配

## 已经完成的"参考样板"
- `lib/design/palette.dart` / `semantic_colors.dart` / `app_theme.dart` / `app_colors.dart`
- `lib/main.dart`（已经全部迁移完成）
- `lib/design/widgets/gradient_badge.dart`（**还没改**，可以作为对照参考，**不要重复改**）

## 不要动的东西
- `lib/models/` —— 业务数据模型
- `lib/services/` —— 业务服务（database / notification / barcode / nearby / purchase）
- `lib/providers/` —— 状态管理（item / family / settings / user）
- `lib/constants.dart` —— 全局常量
- `lib/l10n/` —— 国际化
- 数据库结构 / SQL / 通知 / 扫描 / 购买 等业务逻辑
- `lib/screens/ui_preview_screen.dart` —— 这是设计预览屏，已是新版，可以不动