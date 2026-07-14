# 当前项目状态

更新时间：2026-07-13

## 已完成

- `flutter analyze --no-pub` 当前通过，结果为 `No issues found!`。
- `Item` 支持药品、食品、化妆品、日用品、电子产品、其他六类物品。
- 电子产品支持购买日期、保修月数、保修截止日期、剩余天数和保修状态持久化。
- 设置页的物品数量和条码缓存数量使用数据库/缓存的真实值，不是占位字符串。
- Android 启动主题、Android 12 SplashScreen、普通启动背景和 `NormalTheme` 均使用统一品牌蓝色，减少启动白屏。
- Android、iOS、Web 的图标资源已更新为蓝色品牌图标。
- 正式页面已接入统一主题工厂、语义色和现代卡片/空状态组件。
- 添加物品页的图标选择器已按物品分类分组；切换分类会切换到对应图标池的默认图标。
- 编辑历史数据时，如果旧图标不在当前分类图标池中，会保留为兼容选项，不会丢失用户选择。
- 添加物品页已改用当前主题的 `ColorScheme`，浅色和深色模式下的背景、文字、边框和选中态会跟随主题切换。
- 期限模型已支持“有效期、保修期、无期限”三种类型；旧数据默认兼容为有效期，新字段通过数据库版本 6 迁移保存。
- 添加物品页会根据期限类型显示对应字段：有效期日期、购买日期与保修时长，或无期限说明。
- Pro 购买服务已统一为单例，购买页与启动阶段共享购买流；购买、恢复购买、商品不存在和商店不可用均有明确状态处理。
- Pro 商品 ID 固定为 `premium_unlock`，Google Play/App Store 的商品创建和测试要求见 `docs/IN_APP_PURCHASE_SETUP.md`。

## 当前工作区

- 工作区包含较多未提交改动，涉及正式 Dart 页面、设计系统、平台图标和启动资源。
- `DESIGN_SYSTEM.md`、`MIGRATION_PLAN.md`、`MIGRATION_SPEC.md`、`ui_preview.html` 和 `lib/screens/ui_preview_screen.dart` 是设计迁移资料与预览实现。
- Flutter 临时状态目录已清理。
- `android/build/reports/problems/problems-report.html` 是构建工具生成的跟踪文件，仍显示为修改状态；提交前应确认是否纳入版本控制。
- `lib/main.dart.bak` 是备份文件，暂时保留，避免误删用户的历史版本。

## 尚需人工验证

- 在 Android 真机上冷启动、二次启动和深色模式下确认没有白屏或主题闪烁。
- 在不同屏幕宽度下检查添加物品页图标选择器、长名称和保修字段布局。
- 若准备提交代码，先审阅 `git status` 中的平台图片和未跟踪文档，再决定分批提交或合并提交。

## 验证命令

```text
flutter analyze --no-pub
dart format lib/screens/add_edit_item_screen.dart
```
