import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../design/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';
import '../constants.dart' as const_alias;
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../services/barcode_service.dart';
import '../services/database_service.dart';
import '../widgets/loading_indicator.dart';
import '../l10n/app_localizations.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _cacheCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
      context.read<UserProvider>().loadUser();
      _loadCacheCount();
    });
  }

  Future<void> _loadCacheCount() async {
    final count = await BarcodeService.getCacheCount();
    if (mounted) setState(() => _cacheCount = count);
  }

  void _editNickname() {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    final ctrl = TextEditingController(text: user.nickname);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('edit_nickname')),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: context.tr('nickname')), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                context.read<UserProvider>().updateNickname(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCache() async {
    final path = await BarcodeService.exportCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cache_exported', {'path': path})), duration: const Duration(seconds: 3)),
      );
    }
  }

  Future<void> _importCache() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final count = await BarcodeService.importCache(result.files.single.path!);
        if (mounted) {
          _loadCacheCount();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('cache_import_success', {'count': count.toString()}))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('cache_import_fail'))),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('clear_cache_title')),
        content: Text(context.tr('clear_cache_body', {'count': _cacheCount.toString()})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('clear'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await BarcodeService.clearCache();
      _loadCacheCount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('cache_cleared'))));
      }
    }
  }

  Future<void> _exportFullBackup() async {
    try {
      final db = DatabaseService();
      final path = await db.exportAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('backup_success', {'path': path})), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('backup_fail', {'error': e.toString()}))),
        );
      }
    }
  }

  Future<void> _importFullBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        if (!mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.tr('restore')),
            content: Text(context.tr('restore_confirm')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('confirm'))),
            ],
          ),
        );
        if (confirm == true) {
          final db = DatabaseService();
          final counts = await db.importAllData(result.files.single.path!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('restore_result', {'drugs': counts['drugs'].toString(), 'members': counts['members'].toString()}))),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('restore_fail'))),
        );
      }
    }
  }

  Future<void> _sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'lovesmile811@gmail.com',
      queryParameters: {
        'subject': '${context.tr('app_name')} Feedback',
        'body': '请描述您的意见或建议：\n\n',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('feedback_mail_fail'))),
        );
      }
    }
  }

  void _showPolicy(String type) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final (title, content) = switch (type) {
      'privacy' => (context.tr('privacy_policy'), isZh ? _privacyPolicy : _privacyPolicyEn),
      'terms' => (context.tr('user_agreement'), isZh ? _userAgreement : _userAgreementEn),
      'sdk' => (context.tr('sdk_list'), isZh ? _sdkList : _sdkListEn),
      _ => ('', ''),
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.6)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('close'))),
        ],
      ),
    );
  }

  // 隐私政策
  static const String _privacyPolicy = '''
本应用尊重并保护您的隐私。请您仔细阅读以下隐私政策：

1. 信息收集
本应用所有数据（物品信息、家庭成员信息、条码缓存等）仅存储于您设备的本地 SQLite 数据库中，不会自动上传至任何服务器。

2. 相机权限
条码扫描功能需要相机权限，仅用于扫描物品条码。我们不会通过相机收集任何其他信息。

3. 网络请求
条码查询时，我们会向第三方 API 服务（阿里云市场、Open Food Facts）发送条码编号以获取物品信息。这些服务可能记录您的请求以提供 API 服务。您可在设置中关闭自动查询。

4. 附近设备权限
家庭同步功能使用 Nearby Connections API，通过 WiFi/蓝牙在局域网内发现附近设备并传输物品数据。此功能需要位置或附近设备权限，仅在您主动开启时使用。

5. 文件存储
导出缓存和导入照片时需要读写存储权限。导出的缓存文件仅包含物品条码信息，不包含个人身份信息。

6. 信息分享
当您使用分享功能时，系统会调用系统分享面板。您主动选择的分享目标（如微信、QQ 等）将收到您选择分享的物品信息。

7. 第三方服务
本应用使用了若干第三方 SDK（详见第三方SDK清单），这些 SDK 可能收集设备信息以提供服务。

8. 联系我们
如您对本隐私政策有任何疑问，请通过应用内「设置-意见反馈」联系我们。

本隐私政策更新日期：2026年5月
''';

  // 用户协议
  static const String _userAgreement = '''
欢迎使用到期管家。请您仔细阅读以下协议：

1. 服务说明
本应用是一款本地优先的到期管家，提供物品信息录入、条码扫描、到期提醒等功能。所有数据默认存储于本地设备。

2. 用户责任
- 用户应自行备份重要数据
- 物品有效期信息仅供参考，不构成医疗建议
- 用户应对录入的物品信息准确性负责

3. 免责声明
- 本应用不提供用药指导，不承担因用药不当产生的任何责任
- 到期提醒功能基于用户录入的日期计算，因录入错误导致的后果需用户自行承担
- 数据丢失风险：建议定期导出备份

4. 知识产权
本应用及其所有内容的知识产权归开发者所有。

5. 协议修改
我们保留修改本协议的权利。修改后的协议将在应用内公布。

6. 法律适用
本协议适用中华人民共和国法律。
''';

  // 第三方SDK清单
  static const String _sdkList = '''
本应用使用的第三方SDK如下：

1. sqflite / SQLite
- 用途：本地数据存储
- 收集信息：无（仅本地存储）
- 官网：https://pub.dev/packages/sqflite

2. mobile_scanner
- 用途：条码扫描
- 收集信息：相机权限（本地处理，无上传）
- 官网：https://pub.dev/packages/mobile_scanner

3. flutter_local_notifications
- 用途：本地通知提醒
- 收集信息：无（本地通知）
- 官网：https://pub.dev/packages/flutter_local_notifications

4. image_picker / file_picker
- 用途：选择照片和文件
- 收集信息：存储/媒体权限
- 官网：https://pub.dev/packages/image_picker

5. share_plus
- 用途：系统分享
- 收集信息：无
- 官网：https://pub.dev/packages/share_plus

6. http
- 用途：API 网络请求（条码查询）
- 收集信息：请求的条码编号、IP地址
- 官网：https://pub.dev/packages/http

7. nearby_connections (Google Nearby Connections)
- 用途：局域网设备发现与数据传输
- 收集信息：位置/附近设备权限、WiFi状态
- 官网：https://developers.google.com/nearby

8. path_provider / shared_preferences
- 用途：文件路径和应用设置存储
- 收集信息：无
- 官网：https://pub.dev/packages/path_provider

9. permission_handler
- 用途：权限管理
- 收集信息：设备权限状态
- 官网：https://pub.dev/packages/permission_handler

10. provider
- 用途：状态管理
- 收集信息：无
- 官网：https://pub.dev/packages/provider
''';

  // ====== English legal texts ======
  static const String _privacyPolicyEn = '''
This application respects and protects your privacy.

1. Information Collection
All data (item info, family members, barcode cache) is stored locally in your device's SQLite database. No data is automatically uploaded to any server.

2. Camera Permission
Barcode scanning requires camera permission, used only for scanning product barcodes.

3. Network Requests
When looking up barcodes, we send the barcode number to third-party APIs (Alibaba Cloud Marketplace, Open Food Facts). You can disable auto-lookup in Settings.

4. Nearby Devices Permission
Family sync uses Nearby Connections API over WiFi/Bluetooth. Location or nearby devices permission is required only when you actively enable this feature.

5. File Storage
Exporting cache and importing photos requires storage read/write permission.

6. Information Sharing
When you use the share feature, the system share sheet is invoked. Your selected target (e.g. WeChat, QQ) will receive the item information you choose to share.

7. Third-Party Services
This app uses several third-party SDKs (see SDK List) which may collect device information to provide their services.

8. Contact Us
If you have any questions, contact us via Settings > Feedback.

Last updated: May 2026
''';

  static const String _userAgreementEn = '''
Welcome to Expiry Tracker. Please read the following terms carefully:

1. Service Description
This app is a local-first expiration tracker. All data is stored locally by default.

2. User Responsibilities
- Users should regularly back up important data
- Expiration information is for reference only, not professional advice
- Users are responsible for the accuracy of entered information

3. Disclaimer
- This app does not provide medical guidance
- Expiration reminders are based on user-entered dates
- Data loss risk: regular backups are recommended

4. Intellectual Property
All intellectual property rights belong to the developer.

5. Agreement Changes
We reserve the right to modify this agreement. Changes will be posted in the app.

6. Governing Law
This agreement is governed by the laws of the People's Republic of China.
''';

  static const String _sdkListEn = '''
Third-Party SDKs used in this app:

1. sqflite / SQLite
- Purpose: Local data storage
- Data collected: None (local only)
- Website: https://pub.dev/packages/sqflite

2. mobile_scanner
- Purpose: Barcode scanning
- Data collected: Camera permission (local processing only)
- Website: https://pub.dev/packages/mobile_scanner

3. flutter_local_notifications
- Purpose: Local push notifications
- Data collected: None
- Website: https://pub.dev/packages/flutter_local_notifications

4. image_picker / file_picker
- Purpose: Pick photos and files
- Data collected: Storage/media permission
- Website: https://pub.dev/packages/image_picker

5. share_plus
- Purpose: System share
- Data collected: None
- Website: https://pub.dev/packages/share_plus

6. http
- Purpose: API network requests (barcode lookup)
- Data collected: Barcode number, IP address
- Website: https://pub.dev/packages/http

7. nearby_connections (Google Nearby Connections)
- Purpose: LAN device discovery and data transfer
- Data collected: Location/nearby devices permission, WiFi status
- Website: https://developers.google.com/nearby

8. path_provider / shared_preferences
- Purpose: File paths and app settings storage
- Data collected: None
- Website: https://pub.dev/packages/path_provider

9. permission_handler
- Purpose: Permission management
- Data collected: Device permission status
- Website: https://pub.dev/packages/permission_handler

10. provider
- Purpose: State management
- Data collected: None
- Website: https://pub.dev/packages/provider
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: Consumer2<SettingsProvider, UserProvider>(
        builder: (context, settingsProvider, userProvider, _) {
          if (settingsProvider.isLoading || userProvider.isLoading) {
            return LoadingIndicator(message: context.tr('loading'));
          }
          final settings = settingsProvider.settings;
          final user = userProvider.user;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16, 16, 16,
              16 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              _buildSection(context.tr('personal_info'), [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      (user?.nickname ?? '管')[0],
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  title: Text(user?.nickname ?? context.tr('admin')),
                  subtitle: Text(context.tr('drug_count', {'count': (user?.recordCount ?? 0).toString()})),
                  trailing: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: _editNickname,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSection(context.tr('display_security'), [
                // Theme color
                ListTile(
                  leading: Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
                  title: Text(context.tr('theme_color')),
                  subtitle: Text(context.tr(const_alias.AppTheme.labelKeys[settingsProvider.themeColor] ?? 'theme_green')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final c in const_alias.AppTheme.options)
                        GestureDetector(
                          onTap: () => settingsProvider.setThemeColor(c),
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: const_alias.AppTheme.seeds[c],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: settingsProvider.themeColor == c
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: settingsProvider.themeColor == c
                                ? Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
                // Dark mode switch
                _buildSwitchTile(context.tr('dark_mode'), context.tr('dark_mode_sub'), settingsProvider.isDarkMode, (v) {
                  settingsProvider.setDarkMode(v);
                }),
                // Follow system
                _buildSwitchTile(context.tr('follow_system'), '', settingsProvider.darkModeFollowSystem, (v) {
                  settingsProvider.setDarkModeFollowSystem(v);
                }),
                _buildSwitchTile(context.tr('app_lock'), context.tr('app_lock_sub'), settingsProvider.appLockEnabled, (v) async {
                  if (v) {
                    // Verify biometric capability before enabling
                    final canAuth = await _verifyBiometric();
                    if (!canAuth) return;
                  }
                  settingsProvider.setAppLockEnabled(v);
                }),
              ]),
              const SizedBox(height: 24),
              _buildSection(context.tr('reminder_settings'), [
                _buildSwitchTile(context.tr('reminder_30d'), context.tr('reminder_30d_sub'), settings?.reminder30Days ?? true, (v) {
                  final s = settings!;
                  settingsProvider.updateSettings(s.copyWith(reminder30Days: v));
                }),
                if (settings?.reminder30Days ?? true)
                  _buildTimeTile(context.tr('reminder_time'), settings?.time30Days ?? '20:00', (v) {
                    final s = settings!;
                    settingsProvider.updateSettings(s.copyWith(time30Days: v));
                  }),
                _buildSwitchTile(context.tr('reminder_7d'), context.tr('reminder_7d_sub'), settings?.reminder7Days ?? true, (v) {
                  final s = settings!;
                  settingsProvider.updateSettings(s.copyWith(reminder7Days: v));
                }),
                if (settings?.reminder7Days ?? true)
                  _buildTimeTile(context.tr('reminder_time'), settings?.time7Days ?? '09:00', (v) {
                    final s = settings!;
                    settingsProvider.updateSettings(s.copyWith(time7Days: v));
                  }),
                _buildSwitchTile(context.tr('reminder_3d'), context.tr('reminder_3d_sub'), settings?.reminder3Days ?? true, (v) {
                  final s = settings!;
                  settingsProvider.updateSettings(s.copyWith(reminder3Days: v));
                }),
                if (settings?.reminder3Days ?? true)
                  _buildTimeTile(context.tr('reminder_time'), settings?.time3Days ?? '09:00', (v) {
                    final s = settings!;
                    settingsProvider.updateSettings(s.copyWith(time3Days: v));
                  }),
                _buildSwitchTile(context.tr('reminder_expired'), context.tr('reminder_expired_sub'), settings?.reminderExpired ?? true, (v) {
                  final s = settings!;
                  settingsProvider.updateSettings(s.copyWith(reminderExpired: v));
                }),
                if (settings?.reminderExpired ?? true)
                  _buildTimeTile(context.tr('reminder_time'), settings?.timeExpired ?? '09:00', (v) {
                    final s = settings!;
                    settingsProvider.updateSettings(s.copyWith(timeExpired: v));
                  }),
              ]),
              const SizedBox(height: 24),
              _buildSection(context.tr('barcode_cache'), [
                ListTile(
                  leading: Icon(Icons.storage, color: Theme.of(context).colorScheme.primary),
                  title: Text(context.tr('cache_count', {'count': _cacheCount.toString()})),
                  subtitle: Text(context.tr('cache_subtitle')),
                  trailing: IconButton(
                    icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: _loadCacheCount,
                  ),
                ),
                if (_cacheCount > 0) ...[
                  ListTile(
                    leading: Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.tr('cache_export')),
                    subtitle: Text(context.tr('cache_export_sub')),
                    onTap: _exportCache,
                  ),
                  ListTile(
                    leading: Icon(Icons.file_download, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.tr('cache_import')),
                    subtitle: Text(context.tr('cache_import_sub')),
                    onTap: _importCache,
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    title: Text(context.tr('cache_clear')),
                    onTap: _clearCache,
                  ),
                ],
              ]),
              const SizedBox(height: 24),
              _buildSection(context.tr('data_management'), [
                ListTile(
                  leading: Icon(Icons.backup_outlined, color: Theme.of(context).colorScheme.primary),
                  title: Text(context.tr('backup')),
                  subtitle: Text(context.tr('backup_sub')),
                  onTap: _exportFullBackup,
                ),
                ListTile(
                  leading: Icon(Icons.restore_outlined, color: Theme.of(context).colorScheme.primary),
                  title: Text(context.tr('restore')),
                  subtitle: Text(context.tr('restore_sub')),
                  onTap: _importFullBackup,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSection(context.tr('premium_title'), [
                ListTile(
                  leading: Icon(Icons.workspace_premium, color: Theme.of(context).colorScheme.primary),
                  title: Text(context.tr('premium_title'), style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Consumer<UserProvider>(
                    builder: (context, up, _) => Text(
                      up.user?.isPremium == true ? context.tr('premium_already_owned') : context.tr('premium_subtitle'),
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13),
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                  onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const PremiumScreen())),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSection(context.tr('about'), [
                ListTile(
                  leading: Icon(Icons.feedback_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                  title: Text(context.tr('feedback')),
                  subtitle: Text(context.tr('feedback_sub')),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                  onTap: _sendFeedback,
                ),
                ListTile(
                  title: Text(context.tr('version')),
                  trailing: Text('v1.0.0', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                  title: Text(context.tr('privacy_policy')),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                  onTap: () => _showPolicy('privacy'),
                ),
                ListTile(
                  leading: Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                  title: Text(context.tr('user_agreement')),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                  onTap: () => _showPolicy('terms'),
                ),
                ListTile(
                  leading: Icon(Icons.api_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                  title: Text(context.tr('sdk_list')),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                  onTap: () => _showPolicy('sdk'),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8, left: 4),
          child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      value: value,
      activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      activeThumbColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
    );
  }

  Widget _buildTimeTile(String title, String currentTime, ValueChanged<String> onChanged) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: Text(currentTime, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: () async {
        final parts = currentTime.split(':');
        final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        final picked = await showTimePicker(context: context, initialTime: initial);
        if (picked != null) {
          onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
    );
  }

  Future<bool> _verifyBiometric() async {
    final auth = LocalAuthentication();
    try {
      final canAuth = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canAuth) {
        _showBiometricError('此设备不支持生物识别');
        return false;
      }
      final result = await auth.authenticate(
        localizedReason: '验证生物识别以开启应用锁',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (!result) {
        _showBiometricError('生物识别验证失败');
        return false;
      }
      return true;
    } catch (e) {
      _showBiometricError('验证出错：$e');
      return false;
    }
  }

  void _showBiometricError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }
}
