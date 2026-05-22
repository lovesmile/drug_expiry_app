# 私人药品管家 — 药品有效期管理工具

## 项目概述
一款面向家庭的本地优先药品有效期管理 Flutter 应用。支持药品 CRUD、条码扫描、到期提醒、家庭成员管理及局域网同步等功能。

## 技术栈
- **框架**: Flutter 3.x + Dart 3.x
- **状态管理**: Provider
- **数据库**: SQLite (sqflite)
- **本地化**: flutter_localizations + 自定义 AppLocalizations (中/英文)
- **主题**: Material 3 (colorSchemeSeed 动态取色)
- **持久化**: SharedPreferences (设置项)
- **第三方服务**: 阿里云市场 / Open Food Facts (条码查询 API)

## 功能需求

### 1. 药品管理
- **药品 CRUD**: 添加、编辑、删除药品
  - 必填字段：药品名称、有效期
  - 可选字段：通用名、规格、批号、生产厂家、照片
- **条码扫描**: 集成 mobile_scanner 扫码查询，自动填充药品信息
  - 扫描成功 → 进入添加页并预填数据
  - 扫描失败 → 提示用户确认条码，手动填写
  - 本地缓存查询结果，再次扫码秒查
- **药品图标**: 9 种图标可选（药片、液体、喷雾、颗粒、胶囊、滴剂、健康、急救箱、生物科技）
- **有效期追踪**:
  - 状态分类：有效（>30天）、即将过期（≤30天）、已过期
  - 列表按到期时间/名称/创建时间排序
  - 搜索框实时过滤
  - 归档功能（隐藏/显示归档药品）
- **使用状态**: 使用中 / 已用完 / 已丢弃

### 2. 药品列表
- **统计卡片**: 显示总数、有效、即将过期、已过期数量
- **标签页**: 全部 / 有效 / 即将过期 / 已过期 + 归档切换
- **下拉刷新**: RefreshIndicator 手动刷新
- **空状态**: 无药品时显示引导提示

### 3. 药品详情
- **基本信息**: 名称、通用名、规格、批号、生产厂家、有效期
- **照片展示**: 大图浏览
- **倒计时卡片**: 大字体显示剩余天数/已过期天数
- **操作入口**: 编辑、分享、标记已用完/已丢弃

### 4. 家庭与同步
- **家庭成员管理**: 添加/移除成员
- **局域网同步**: 基于 nearby_connections 实现
  - 设备发现（同一 WiFi 下自动发现）
  - 数据同步（药品 + 成员数据双向合并）
  - 连接提示和操作引导
- **邀请码**: 成员展示邀请码，支持复制

### 5. 提醒通知
- **本地通知**: flutter_local_notifications
- **提醒规则**（可配置时间）:
  - 30 天提醒
  - 7 天提醒
  - 3 天提醒
  - 过期提醒

### 6. 设置
- **个人信息**: 昵称编辑、药品统计
- **主题颜色**: 绿色 / 蓝色 / 青色
- **深色模式**: 独立开关 / 跟随系统
- **应用锁**: biometric + local_auth 指纹/面容解锁
- **条码缓存管理**: 查看缓存数量、导出、导入、清除
- **数据管理**: 完整数据备份（JSON）和恢复
- **意见反馈**: 邮件发送
- **法律文档**: 隐私政策、用户协议、第三方 SDK 清单

### 7. 界面与体验
- **多语言**: 简体中文 / English（自动跟随系统语言）
- **Material 3**: 动态取色，主题跟随设置实时切换
- **App 图标**: flutter_launcher_icons 生成
- **应用名称**: "私人药品管家"

### 8. 安全与隐私
- **本地存储优先**: 所有数据存于设备本地 SQLite，不自动上传
- **应用锁**: 可选 biometric 验证进入
- **权限按需申请**: 相机（扫码）、位置（附近设备）、存储（备份导入导出）

## 项目结构

```
lib/
├── main.dart                    # 入口：Provider 顶层注入 + MaterialApp
├── constants.dart               # 颜色、尺寸、主题色定义
├── l10n/
│   └── app_localizations.dart   # 中/英文 翻译 (250+ keys)
├── models/
│   ├── drug.dart                # 药品模型 + 状态计算
│   ├── family_member.dart       # 家庭成员模型
│   ├── user.dart                # 用户信息模型
│   └── reminder_settings.dart   # 提醒设置模型
├── providers/
│   ├── drug_provider.dart       # 药品数据状态管理
│   ├── family_provider.dart     # 家庭成员状态管理
│   ├── user_provider.dart       # 用户状态管理
│   └── settings_provider.dart   # 设置项状态管理
├── screens/
│   ├── drug_list_screen.dart    # 主列表页
│   ├── add_edit_drug_screen.dart# 添加/编辑药品页
│   ├── drug_detail_screen.dart  # 药品详情页
│   ├── scan_screen.dart         # 条码扫描页
│   ├── family_screen.dart       # 家庭与同步页
│   ├── settings_screen.dart     # 设置页
│   └── lock_screen.dart         # 应用锁解锁页
├── services/
│   ├── database_service.dart    # SQLite 数据库操作
│   ├── barcode_service.dart     # 条码查询 + 缓存
│   ├── nearby_service.dart      # 局域网设备发现与同步
│   ├── notification_service.dart# 本地通知
│   └── share_service.dart       # 分享功能
└── widgets/
    ├── drug_card.dart           # 药品列表卡片
    ├── countdown_display.dart   # 倒计时显示组件
    ├── status_badge.dart        # 状态标签（有效/即将过期/已过期）
    ├── empty_state.dart         # 空状态占位
    └── loading_indicator.dart   # 加载指示器
```
