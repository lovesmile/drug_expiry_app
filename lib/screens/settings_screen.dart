import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../design/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_auth/local_auth.dart';
import '../constants.dart' as const_alias;
import '../providers/settings_provider.dart';
import '../providers/item_provider.dart';
import '../providers/user_provider.dart';
import '../providers/family_provider.dart';
import '../services/barcode_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/loading_indicator.dart';
import '../l10n/app_localizations.dart';
import 'webview_screen.dart';

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
    final title = context.tr('cache_export');
    final json = await BarcodeService.buildCacheJson();
    final path = await FilePicker.platform.saveFile(
      dialogTitle: title,
      fileName: 'barcode_cache.json',
      bytes: utf8.encode(json),
    );
    if (path != null && mounted) {
      _showInfoDialog(context.tr('cache_exported', {'path': path}));
    }
  }

  Future<void> _importCache() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        initialDirectory: await _defaultExportDir(),
      );
      if (result != null && result.files.single.path != null) {
        final counts = await BarcodeService.importCache(result.files.single.path!);
        if (mounted) {
          _loadCacheCount();
          _showInfoDialog(context.tr('cache_import_success', {
            'added': counts['added'].toString(),
            'skipped': counts['skipped'].toString(),
          }));
        }
      }
    } catch (e) {
      if (mounted) {
        _showInfoDialog(context.tr('cache_import_fail'));
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
      final title = context.tr('backup');
      final db = DatabaseService();
      final json = await db.buildBackupJson();
      final ts =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final path = await FilePicker.platform.saveFile(
        dialogTitle: title,
        fileName: 'expiry_backup_$ts.json',
        bytes: utf8.encode(json),
      );
      if (path != null && mounted) {
        _showInfoDialog(context.tr('backup_success', {'path': path}));
      }
    } catch (e) {
      if (mounted) {
        _showInfoDialog(context.tr('backup_fail', {'error': e.toString()}));
      }
    }
  }

  Future<void> _importFullBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        initialDirectory: await _defaultExportDir(),
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
          // 导入成功后立刻重载各 provider，使主页/家庭页/设置等
          // Consumer 重建，避免用户必须重启 app 才看到恢复后的数据。
          if (!mounted) return;
          await Future.wait([
            context.read<ItemProvider>().loadItems(),
            context.read<FamilyProvider>().loadMembers(),
            context.read<UserProvider>().loadUser(),
            context.read<SettingsProvider>().loadSettings(),
          ]);
          await NotificationService.rescheduleFromDb();
          if (mounted) {
            _showInfoDialog(context.tr('restore_result', {
              'added': counts['drugs'].toString(),
              'drugDups': counts['drugDups'].toString(),
            }));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showInfoDialog(context.tr('restore_fail'));
      }
    }
  }

  // 导入对话框默认进入导出所在的 Downloads 目录，避免用户到处翻找。
  Future<String?> _defaultExportDir() async {
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    return dir.path;
  }

  // 导出成功：弹窗显示 SAF 实际保存位置。
  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('confirm'))),
        ],
      ),
    );
  }

  void _openSurvey() {
    final title = context.tr('feedback');
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => WebViewScreen(
          url: 'https://forms.gle/1Ja3129VLPjqFtjW9',
          title: title,
        ),
      ),
    );
  }

  void _showPolicy(String type) {
    final entry = switch (type) {
      'privacy' => (
        'https://lovesmile.github.io/expiry-tracker-privacy/index.html',
        context.tr('privacy_policy'),
      ),
      'terms' => (
        'https://lovesmile.github.io/expiry-tracker-privacy/terms.html',
        context.tr('user_agreement'),
      ),
      'sdk' => (
        'https://lovesmile.github.io/expiry-tracker-privacy/sdk.html',
        context.tr('sdk_list'),
      ),
      _ => ('', ''),
    };
    if (entry.$1.isEmpty) return;
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => WebViewScreen(url: entry.$1, title: entry.$2),
      ),
    );
  }

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
                  subtitle: Text(context.tr('drug_count', {'count': context.read<ItemProvider>().totalCount.toString()})),
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
                // Dark mode switch — 显示实际生效值，开启"跟随系统"时强制 off
                _buildSwitchTile(context.tr('dark_mode'), context.tr('dark_mode_sub'), settingsProvider.effectiveDarkMode, (v) {
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
              Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Text(
                  context.tr('reminder_hint'),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
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
              _buildSection(context.tr('about'), [
                ListTile(
                  leading: Icon(Icons.feedback_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                  title: Text(context.tr('feedback')),
                  subtitle: Text(context.tr('feedback_sub'), maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                  onTap: _openSurvey,
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
    } on PlatformException catch (e) {
      _showBiometricError(_biometricErrorMessage(e));
      return false;
    } catch (e) {
      _showBiometricError('验证出错：$e');
      return false;
    }
  }

  String _biometricErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return '生物识别功能不可用';
      case 'NotEnrolled':
        return '未设置生物识别，请先在系统设置中添加指纹或面容';
      case 'LockedOut':
        return '生物识别已被锁定，请稍后再试';
      case 'PermanentlyLockedOut':
        return '生物识别已被永久锁定，请在系统设置中重置';
      case 'PasscodeNotSet':
        return '设备未设置锁屏密码，请先在系统设置中设置';
      default:
        return '验证失败：${e.message ?? e.code}';
    }
  }

  void _showBiometricError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }
}
