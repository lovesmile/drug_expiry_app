# 当前项目状态

更新时间：2026-07-18（备份导入去重 + release ProGuard / reschedule 防弹；i18n 文案同步）

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
- 期限模型已支持"有效期、保修期、无期限"三种类型；旧数据默认兼容为有效期，购买日期与保修月数通过数据库版本 5 迁移，期限类型字段通过版本 6 迁移。
- 添加物品页会根据期限类型显示对应字段：有效期日期、购买日期与保修时长，或无期限说明。
- 商业化方案切换为 Google Mobile Ads（横幅广告）；旧的 in_app_purchase / premium_screen / purchase_service 已移除；`docs/IN_APP_PURCHASE_SETUP.md` 已删除。
- **真实定时通知**（`NotificationService`）：使用 `zonedSchedule` 排期到 Android `AlarmManager`，4 个桶（30 天 / 7 天 / 3 天 / 过期）独立开关 + 时间，文案跟随系统语言（中英），ID 方案 `item.id * 10 + offset`。
  - 触发点：增/删/改物品、改提醒设置、app 冷启动都会触发 `rescheduleFromDb()` 全清重排
  - 不补发过去的触发点；过期桶的 fireAt 已在过去会被跳过
  - 模式：`AndroidScheduleMode.inexactAllowWhileIdle`（无 EXACT_ALARM 权限，Play 审核友好）
  - iOS 走 DarwinUNUserNotificationCenter，本期未真机验证
- **app 内 SnackBar 兜底**（`item_list_screen.dart:35`）：冷启动时若仍有「即将过期」或「已过期」物品，底部弹一次聚合提示（"您有 N 个即将到期，M 个已过期" + "查看" 跳到对应 tab），覆盖通知被禁用、延迟或用户长时间未启动的场景。同一会话内 `_hasShownFallbackReminder` 标志防重入。
  - SnackBar 显示走根 ScaffoldMessenger (`main.dart` `rootScaffoldMessengerKey`)。配 `HomeSnackBarHider`(NavigatorObserver)在 push/replace/pop 时主动调用 `hideCurrentSnackBar()`，避免 SnackBar 跨页面悬挂。
- **备份导入刷新**（`settings_screen.dart:_importFullBackup`）：JSON 备份恢复完成后 `Future.wait` 并行重载 ItemProvider/FamilyProvider/UserProvider/SettingsProvider，再 `NotificationService.rescheduleFromDb()` 按恢复后的数据重新排期；之前必须重启 app 才能看到恢复的数据，现已在主页/家庭页/设置页即时可见。
- **备份导入去重**（`database_service.dart:importAllData`）：导入前先按 `(name, deadline_type, expiry_date)` 预加载现有物品键集合，循环内命中跳过；家庭成员按 `name` 去重；提醒设置保持单行 upsert。结果弹窗区分"新增 N、跳过 M"。"恢复"确认弹窗文案同步改成"将跳过已存在物品"，避免此前"合并"措辞造成重复堆叠的歧义。
- **条码缓存导入去重**（`database_service.dart:insertCacheIfMissing` + `barcode_service.dart:importCache`）：新增 INSERT OR IGNORE 路径返回新行 id；导入循环判断 id>0 计 added，反之 skipped。线上查询复用原 `cacheBarcode`（REPLACE）以保持"重新查询会刷新最新数据"的语义。
- **启动期重活异步化**（`main.dart`）：`main()` 不再串行 await Firebase / Notification / Ad 三个 init；改为首帧后用 `Future<void>.microtask(_bootstrapBackgroundServices)` 异步跑（每个 init 用 try/catch 吞错）。实测冷启 ActivityManager TotalTime 稳定在 ~4.1s，从 `am start` 到首页可见约 7.5s；Firebase/Notification/Ad 不再阻塞 UI 首帧。
- **release ProGuard 规则**（`android/app/proguard-rules.pro` + `build.gradle.kts:buildTypes.release`）：必须保留 `com.dexterous.flutterlocalnotifications.**` 的类成员与 Gson 泛型签名。否则 release 包 R8 会擦掉 `cancelAll()` 内部匿名 `TypeToken` 的类型参数，方法通道抛 `RuntimeException: Missing type parameter`，让所有走 `rescheduleFromDb()` 的路径（冷启动 / 增删改 / 备份导入刷新）静默失败。
- **notification reschedule 防弹**（`notification_service.dart:rescheduleFromDb`）：外层包 try/catch、`cancelAll()` 单独 try/catch；任何内部异常吃掉（不抛）。下一步增删改 / 下一次冷启动会自然重试，已经触发的闹钟照旧能正常 fire。
- **已知行为**：在「过期当天 + timeExpired 时刻」前后几分钟内打开 app，SnackBar 与系统通知会短暂同时出现（不同位置）。已在设置页 reminder section 下方加灰字提示。

## 当前工作区

- 工作区包含较多未提交改动，涉及正式 Dart 页面、设计系统、平台图标和启动资源。
- `DESIGN_SYSTEM.md`、`MIGRATION_PLAN.md`、`MIGRATION_SPEC.md`、`ui_preview.html` 和 `lib/screens/ui_preview_screen.dart` 是设计迁移资料与预览实现。
- Flutter 临时状态目录已清理。
- App 图标已按设计系统重做为蓝青渐变时钟 + 绿色完成标记，并同步生成 Android、iOS、Web 各尺寸资源；启动纯色背景统一为 `#2563EB`。
- `android/build/reports/problems/problems-report.html` 是构建工具生成的跟踪文件，仍显示为修改状态；提交前应确认是否纳入版本控制。

## 尚需人工验证

- 在 Android 真机上冷启动、二次启动和深色模式下确认没有白屏或主题闪烁。
- 在不同屏幕宽度下检查添加物品页图标选择器、长名称和保修字段布局。
- 通知的真实到点弹出：当前已用 `dumpsys alarm` 验证 4 个 alarm 正确注册（最早 30 天桶 2026-07-21 20:00）；到点实际弹出建议在正式发布前用一台真机跑 24-48h 验证。
- 若准备提交代码，先审阅 `git status` 中的平台图片和未跟踪文档，再决定分批提交或合并提交。

## 验证命令

```text
flutter analyze --no-pub
adb shell dumpsys alarm | grep -A 5 "com.lovesmile.expiry"   # 查看待触发 alarm
adb shell dumpsys notification | grep -B 1 "com.lovesmile"   # 查看通知通道和已发布数
```
