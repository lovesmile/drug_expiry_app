# 设计系统与主题规范

> 目的：把"硬编码颜色 / 平行色板"清干净，让 8 个正式页面在浅色 / 深色 / 三套主题色下都正确呈现。
>
> 适用范围：`lib/` 下所有业务代码。

---

## 1. 现状（重构前）

- `lib/design/palette.dart`：跨主题不变的色（品牌色 / 状态色主体）。
- `lib/design/semantic_colors.dart`：跨主题切换的语义色 `AppSemanticColors`（light / dark 两套），通过 `context.semantic` 取。
- `lib/design/app_theme.dart`：集中的 `AppTheme.build()` 工厂，构造 `ThemeData`。
- `lib/design/app_colors.dart`：**与上面三个并存**。里面残留：
  - 旧 `AppColorsV2`（硬编码深浅两套背景 / 文字 / 边框）；
  - 旧 `AppGradients`、`AppRadius`、`AppShadowsV2`（命名与新设计系统冲突）。
- `lib/main.dart`：**没走 `AppTheme.build()`**，自己手写 `ThemeData`，所有颜色都写死。
- 8 个正式页面：除了 `item_list_screen` 用了新 `ModernItemCard` / `ModernEmptyState`，**其余都在用 `AppColorsV2.*`**。
- `lib/design/widgets/modern_item_card.dart`：`Row` 里塞三段内容窄屏溢出 60px。
- `lib/design/widgets/modern_empty_state.dart`：`IntrinsicHeight` + `MainAxisSize.max` 错配，溢出 31px。

---

## 2. 目标架构

四层职责分离，每层只暴露"该层应该关心"的内容。

```
┌──────────────────────────────────────────────────────────────┐
│  UI 代码（screens / widgets / 业务 widget）                    │
│      ↓ 只用 colorScheme / context.semantic / 应用层 token      │
├──────────────────────────────────────────────────────────────┤
│  应用层 token（app_colors.dart 门面）                          │
│  - AppColorsV2 : 旧别名（逐步淘汰，保留向后兼容）              │
│  - AppGradients: 品牌 / 状态渐变                               │
│  - AppRadius   : 圆角（数值常量 + 预包装 BorderRadius）        │
│  - AppShadows  : 按 Brightness 自适应阴影                      │
├──────────────────────────────────────────────────────────────┤
│  设计系统核心（app_theme.dart / palette.dart / semantic_colors.dart）│
│  - AppPalette       : 跨主题不变的色（const）                  │
│  - AppSemanticColors: 跨主题的语义色（ThemeExtension）         │
│  - AppTheme.build() : 集中 ThemeData 工厂                     │
├──────────────────────────────────────────────────────────────┤
│  Material 3 ColorScheme（Theme.of(context).colorScheme）       │
│  - surface / onSurface / outlineVariant / primary / ...        │
└──────────────────────────────────────────────────────────────┘
```

**核心原则**

- **零硬编码**：业务代码不允许 `Color(0xFF...)`、`AppColorsV2.bgMain` 这种跨主题固定值。
- **角色用 ColorScheme，含义用 AppPalette，状态容器用 semantic**。
- **集中主题**：所有 `ThemeData` 子主题（AppBar / Card / Input / Dialog / Switch ...）由 `AppTheme.build()` 统一产出。页面里只允许通过 `Theme.of(context).XXXTheme` 覆盖"特例"。

---

## 3. 取色规则

| 用途 | 推荐来源 | 备注 |
| --- | --- | --- |
| 主背景 | `Theme.of(context).colorScheme.surface` | 浅色 = 接近白，深色 = 接近黑 |
| 卡片 / 浮层背景 | `colorScheme.surfaceContainer` / `surfaceContainerLow` | 已有层次感 |
| 主要文字 | `colorScheme.onSurface` | 跟随主题 |
| 次要文字 | `colorScheme.onSurfaceVariant` | 跟随主题 |
| 输入框填充色 | `colorScheme.surfaceContainerLow` | 已在 `InputDecorationTheme` 集中 |
| 分割线 | `Theme.of(context).dividerColor` 或 `colorScheme.outlineVariant` | |
| 状态主体色（valid=绿 / warning=橙 / expired=红） | `AppPalette.statusValid` / `statusWarning` / `statusExpired` | 跨主题不变，**只在深色背景下用**时降低饱和度 |
| 状态容器色（浅绿 / 浅红 / 浅橙） | `context.semantic.statusValidContainer` 等 | **自动跟随主题**：浅色=浅绿，深色=深绿 |
| 状态容器上的文字 | `context.semantic.onStatusValidContainer` 等 | 同上 |
| 品牌色（按钮 / FAB 背景） | `Theme.of(context).colorScheme.primary` | 用户切换主题色后自动跟随 |
| 警告操作文字色（"删除"等） | `colorScheme.error` | Material 3 标准 error 角色 |

---

## 4. 主题切换保证

要做到切换"深色模式"时，**所有页面自动正确**：

1. 所有颜色必须**经过 `Theme.of(context).colorScheme` 或 `context.semantic`**，**不能直接 const `Color` 引用**。
2. 阴影 / 渐变这种"半绝对"的视觉元素，使用 `AppShadows.card(brightness)` / `AppGradients.surfaceFor(brightness)` 这种**接受 `Brightness` 的 API**。
3. 渐变背景（如 PremiumScreen 顶部那块）必须按 `Theme.of(context).brightness` 选不同变体，否则深色模式下"白→浅灰"渐变会非常刺眼。
4. `main.dart` 用 `MaterialApp.builder` + `AnnotatedRegion` 让状态栏图标随主题切换（已有 `AppTheme.systemUiOverlayStyle` 工具）。

---

## 5. 命名与文件边界

| 名称 | 位置 | 职责 |
| --- | --- | --- |
| `AppPalette` | `palette.dart` | 跨主题不变色（const） |
| `AppSemanticColors` | `semantic_colors.dart` | 跨主题语义色（ThemeExtension） |
| `AppTheme` | `app_theme.dart` | `ThemeData` 工厂 + `systemUiOverlayStyle` |
| `AppGradients` | `app_colors.dart` | 渐变组合 |
| `AppRadius` | `app_colors.dart` | 圆角（`xs` / `sm` / `md` / `lg` / `xl` / `xxl` / `full` + 预包装 `small` / `medium` / `large` / `card` / `button` / `pill`）|
| `AppShadows` | `app_colors.dart` | 按 `Brightness` 自适应阴影 |
| `AppColorsV2` | `app_colors.dart` | **旧兼容层**，新代码**禁止**使用 |
| `context.semantic` | `semantic_colors.dart` 扩展 | `Theme.of(context).extension<AppSemanticColors>()` 的语法糖 |

**`AppRadius` 新约定**：去掉旧的 `cardRadius` / `smallRadius` 这种带后缀的别名，新代码统一用 `AppRadius.card` / `AppRadius.small` 这种**短名**。旧别名保留为 const 转发，以便不强制全量改名。

**`AppShadows` 新约定**：所有静态方法必须接受 `Brightness`，避免深色模式下出现"脏阴影"。

---

## 6. 迁移计划（按依赖顺序）

1. **系统层**（一次性）
   - ① `palette.dart` 补齐 `statusValidLight` / `statusWarningLight` / `statusExpiredLight` / `divider` / `shadow` / `overlay`（让旧 `AppColorsV2.*` 引用能找到值）。
   - ② `app_colors.dart` 整文件重写为门面：`export` 三个核心模块，本地只放 `AppColorsV2`（兼容别名）/`AppGradients` / `AppRadius` / `AppShadows`。
   - ③ `main.dart` 接入 `AppTheme.build(brightness, seed)`，移除所有硬编码 `AppColorsV2.*` 和手写 `ThemeData`。
2. **设计 widget 修复**（必做）
   - ④ `modern_item_card.dart` 底部 "有效期 + 保修期 + 删除" `Row` → 改成自适应（窄屏 `Wrap` 或对每段加 `Flexible` + 文本 `ellipsis`）。
   - ⑤ `modern_empty_state.dart` 去掉 `IntrinsicHeight` + `MainAxisSize.max` 错配，改成 `Column(mainAxisSize: MainAxisSize.min)`，外层交给 `Scaffold` / `ListView` 撑。
3. **业务页面应用**（每完成 1-2 个让用户 review）
   - ⑥ `item_list_screen`（首页）
   - ⑦ `add_edit_item_screen`
   - ⑧ `item_detail_screen`
   - ⑨ `family_screen`
   - ⑩ `scan_screen`
   - ⑪ `premium_screen`
   - ⑫ `lock_screen`
   - ⑬ `settings_screen`
4. **一致性扫描**
   - ⑭ 全量扫 `AppColorsV2.` 残留，逐个替换为 `colorScheme` / `context.semantic` / `AppPalette.*`。
   - ⑮ `flutter analyze` 兜底。
   - ⑯ 浅色 / 深色 / 三套主题色的人工 / 截图回归。

---

## 7. 验收标准

- [ ] `grep -r "AppColorsV2\." lib/` 仅在 `app_colors.dart`（兼容别名）出现，**业务代码 0 处**。
- [ ] `grep -rE "Color\(0x" lib/` 仅在 `palette.dart` / `semantic_colors.dart` / `app_colors.dart` 出现，**业务代码 0 处**。
- [ ] `flutter analyze` 0 error。
- [ ] 切换深色模式，所有页面无"硬白色背景" / "硬黑色文字" / "刺眼渐变"。
- [ ] 切换主题色（绿 / 蓝 / 青），所有页面的按钮、FAB、强调色随之改变。
- [ ] 修复两个 RenderFlex 溢出 bug。
- [ ] `ModernItemCard` / `ModernEmptyState` / `GradientStatusBadge` / `WarrantyBadge` 仍可被复用。

---

## 8. 后续可选（不在本次范围）

- 把 `ui_preview_screen` 升级为"主题切换器"（一键切浅色 / 深色 / 三套主题色截图），方便回归。
- 接入 `flex_color_scheme` 或自己写一组 `AppSemanticColors.dark` 的精细调优。
- 把 `family_screen` 的连接状态徽章也接进 `context.semantic`。
