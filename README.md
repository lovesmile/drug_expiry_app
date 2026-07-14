# 过期管家 - 物品有效期管理工具

<p align="center">
  <img src="assets/icon/app_icon.png" width="80" alt="App Icon">
</p>

<p align="center">
  <strong>一款面向家庭的多类别物品有效期追踪 Flutter 应用</strong>
  <br>
  支持药品、食品、化妆品、日用品等物品的 CRUD、条码扫描、到期提醒、家庭成员管理及局域网同步等功能。
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-blue" alt="Dart">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

---

## 功能概览

### 1. 物品管理
- **物品 CRUD**：添加、编辑、删除物品
  - 必填字段：名称、有效期
  - 可选字段：通用名、规格、批号、厂家、图片
- **条码扫描**：集成 mobile_scanner 扫码，自动填充物品信息
  - 扫描成功 → 进入添加页并预填数据
  - 扫描失败 → 提示用户确认条码，手动录入
  - 本地缓存查询结果，再次扫码秒响应
- **物品图标**：9 种图标可选（药片、液体、喷雾、颗粒、胶囊、滴剂、保健、包/套装、食品）
- **5 种类别**：

  | 类别 | 说明 |
  |------|------|
  | 药品 | 处方药、非处方药、保健品等 |
  | 食品 | 零食、调味品、保健品食品等 |
  | 化妆品 | 护肤品、彩妆、洗护用品等 |
  | 日用品 | 清洁用品、纸品、家居用品等 |
  | 其他 | 不属于以上类别的物品 |

- **有效期状态**：
  - 有效（>30天）
  - 即将过期（≤30天）
  - 已过期
- **使用状态**：使用中 / 已用完 / 已丢弃

### 2. 物品列表
- **统计卡片**：显示总数、有效、即将过期、已过期数量
- **标签筛选**：全部 / 有效 / 即将过期 / 已过期 + 归档筛选
- **下拉刷新**：RefreshIndicator 手动刷新
- **排序功能**：按到期日期（升/降）、名称（升/降）、创建时间
- **搜索功能**：实时过滤名称、通用名、厂家
- **空状态**：无物品时显示引导提示

### 3. 物品详情
- **基本信息**：名称、通用名、规格、批号、厂家、有效期
- **图片展示**：大图浏览
- **倒计时卡片**：大字显示剩余天数
- **操作入口**：编辑、分享、标记已用完/已丢弃

### 4. 家庭与同步
- **家庭成员管理**：添加/移除成员，角色区分（管理员/成员）
- **局域网同步**：基于 Nearby Connections 实现
  - 设备发现（同 WiFi 下自动发现）
  - 数据同步（物品 + 成员数据双向合并）
  - 连接提示和操作引导

### 5. 提醒通知
- **本地通知**：flutter_local_notifications
- **提醒规则**（可配置时间）：
  - 30 天提醒
  - 7 天提醒
  - 3 天提醒
  - 过期提醒

### 6. 设置
- **个人信息**：昵称编辑、物品统计
- **主题颜色**：绿色 / 蓝色 / 青色
- **深色模式**：独立开关 / 跟随系统
- **应用锁**：biometric + local_auth 指纹/面容解锁
- **条码缓存管理**：查看缓存数量、导出、导入、清空
- **数据管理**：完整数据备份（JSON）和恢复
- **反馈**：邮件反馈
- **法律文档**：隐私政策、用户协议、第三方 SDK 清单

### 7. 国际化
- **多语言**：简体中文 / English（自动跟随系统语言）
- **Material 3**：动态取色，主题跟随设置实时切换
- **应用图标**：flutter_launcher_icons 自动生成

### 8. 安全与隐私
- **本地存储优先**：所有数据存于设备本地 SQLite，不自动上传
- **应用锁**：可选生物识别验证进入
- **权限按需申请**：扫码（相机）、定位（附近设备）、存储（备份导入导出）

详见：[隐私政策](privacy_policy.md)

---

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.x + Dart 3.x |
| 状态管理 | Provider |
| 数据库 | SQLite (sqflite) |
| 本地化 | flutter_localizations + 自定义 AppLocalizations（中英双语） |
| 主题 | Material 3（colorSchemeSeed 动态取色） |
| 持久化 | SharedPreferences（设置项） |
| 第三方服务 | 阿里云市场 / Open Food Facts（条码查询 API） |

### 核心依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  sqflite: ^2.4.2
  path_provider: ^2.1.5
  path: ^1.9.1
  http: ^1.3.0
  mobile_scanner: ^6.0.7
  provider: ^6.1.2
  intl: ^0.20.2
  shared_preferences: ^2.5.3
  flutter_local_notifications: ^18.0.1
  permission_handler: ^11.3.1
  share_plus: ^10.1.4
  file_picker: ^8.1.7
  image_picker: ^1.1.2
  nearby_connections: ^4.3.0
  url_launcher: ^6.3.1
  local_auth: ^2.3.0
  in_app_purchase: ^3.2.0
```

---

## 项目结构

```
lib/
├── main.dart                        # 入口，Provider 顶层注入 + MaterialApp
├── constants.dart                   # 颜色、尺寸、主题、常量定义
├── l10n/
│   └── app_localizations.dart       # 中英双语翻译（250+ keys）
├── models/
│   ├── item.dart                    # 物品模型 + 状态/类别枚举
│   ├── family_member.dart           # 家庭成员模型
│   ├── user.dart                    # 用户模型
│   └── reminder_settings.dart       # 提醒设置模型
├── providers/
│   ├── item_provider.dart           # 物品数据状态管理
│   ├── family_provider.dart         # 家庭成员状态管理
│   ├── user_provider.dart           # 用户状态管理
│   └── settings_provider.dart       # 设置项状态管理
├── screens/
│   ├── item_list_screen.dart        # 主列表页
│   ├── add_edit_item_screen.dart    # 添加/编辑物品页
│   ├── item_detail_screen.dart      # 物品详情页
│   ├── scan_screen.dart             # 条码扫描页
│   ├── family_screen.dart           # 家庭与同步页
│   ├── settings_screen.dart         # 设置页
│   ├── lock_screen.dart             # 应用锁解锁页
│   └── premium_screen.dart          # Premium 订阅页
├── services/
│   ├── database_service.dart         # SQLite 数据库操作
│   ├── barcode_service.dart         # 条码查询 + 缓存
│   ├── nearby_service.dart          # 局域网设备发现与同步
│   ├── notification_service.dart    # 本地通知
│   ├── share_service.dart           # 分享功能
│   └── purchase_service.dart        # 内购服务
└── widgets/
    ├── item_card.dart               # 物品列表卡片
    ├── countdown_display.dart        # 倒计时显示组件
    ├── status_badge.dart            # 状态标签（有效/即将过期/已过期）
    ├── empty_state.dart             # 空状态占位
    └── loading_indicator.dart       # 加载指示器
```

---

## 隐私与安全

- **数据存储**：所有物品数据默认存储于设备本地 SQLite 数据库，不自动上传至任何服务器
- **应用锁**：可选生物识别（指纹/面容）验证进入应用
- **权限说明**：
  - 相机（扫码）：仅在主动点击扫码按钮时启用
  - 位置（附近设备）：仅在家动同步功能时使用
  - 存储（备份导入导出）：仅在用户主动导出/导入时使用

详见：[隐私政策](privacy_policy.md)

---

## Getting Started

```bash
# 安装依赖
flutter pub get

# 运行开发版本
flutter run

# 构建 Android APK
flutter build apk --release

# 构建 iOS
flutter build ios --release
```

---

## License

MIT License

---

*Made with ❤️ using Flutter*
