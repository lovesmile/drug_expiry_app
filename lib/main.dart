import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'constants.dart';
import 'services/notification_service.dart';
import 'providers/item_provider.dart';
import 'providers/family_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'l10n/app_localizations.dart';
import 'services/purchase_service.dart';
import 'screens/item_list_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ExpiryTrackerApp());
}

class ExpiryTrackerApp extends StatelessWidget {
  const ExpiryTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppStrings.appName,
            supportedLocales: const [Locale('zh'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supported) {
              if (locale?.languageCode == 'zh') return const Locale('zh');
              return const Locale('en');
            },
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: settingsProvider.seedColor,
              scaffoldBackgroundColor: AppColors.bgMain,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.bgSurface,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme: IconThemeData(color: AppColors.textPrimary),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                elevation: 4,
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                  ),
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: settingsProvider.seedColor,
              scaffoldBackgroundColor: AppColors.darkBgMain,
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                ),
              ),
            ),
            themeMode: settingsProvider.themeMode,
            home: const _PrivacyGate(),
          );
        },
      ),
    );
  }
}

/// 隐私协议首次启动门禁
class _PrivacyGate extends StatefulWidget {
  const _PrivacyGate();

  @override
  State<_PrivacyGate> createState() => _PrivacyGateState();
}

class _PrivacyGateState extends State<_PrivacyGate> {
  bool _loading = true;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _checkAgreed();
  }

  Future<void> _checkAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool('privacy_agreed') ?? false;
    if (mounted) {
      setState(() {
        _agreed = agreed;
        _loading = false;
      });
    }
  }

  Future<void> _onAgree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_agreed', true);
    if (mounted) setState(() => _agreed = true);
  }

  void _onDisagree() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('privacy_title')),
        content: Text(context.tr('privacy_disagree_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text(context.tr('exit_app'), style: TextStyle(color: AppColors.statusError)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SplashScreen();
    if (_agreed) return _buildApp();

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题区域
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.brandSecondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.inventory_2, size: 36, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(AppStrings.appName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('v1.0.0', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            // 协议内容
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('welcome'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(context.tr('privacy_summary'), style: TextStyle(fontSize: 13, color: AppColors.textBody, height: 1.6)),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      _linkTile(Icons.privacy_tip_outlined, context.tr('view_privacy'), _showPrivacy),
                      _linkTile(Icons.description_outlined, context.tr('view_terms'), _showTerms),
                      _linkTile(Icons.api_outlined, context.tr('view_sdk'), _showSdk),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
            // 底部按钮
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _onAgree,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: Text(context.tr('agree_continue'), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _onDisagree,
                      child: Text(context.tr('disagree'), style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkTile(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      title: Text(text, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textDisabled),
      onTap: onTap,
    );
  }

  void _showPrivacy() => _showDoc(context.tr('privacy_policy'), _docPrivacy);
  void _showTerms() => _showDoc(context.tr('user_agreement'), _docTerms);
  void _showSdk() => _showDoc(context.tr('sdk_list'), _docSdk);

  void _showDoc(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textBody, height: 1.6)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('close'))),
        ],
      ),
    );
  }

  Widget _buildApp() {
    return const _LockGate();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.inventory_2, size: 48, color: AppColors.brandPrimary),
            ),
            const SizedBox(height: 20),
            const Text(
              AppStrings.appName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'v1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockGate extends StatefulWidget {
  const _LockGate();

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _initPurchaseService();
    _checkLock();
  }

  Future<void> _initPurchaseService() async {
    // Wait for providers to be available
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _purchaseService.init(
      onPremiumUnlocked: () {
        if (mounted) {
          context.read<UserProvider>().setPremium(true);
        }
      },
    );
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> _checkLock() async {
    // Wait for providers to load settings
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    if (settings.appLockEnabled) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LockScreen(), fullscreenDialog: true),
      );
      if (mounted) setState(() => _unlocked = ok == true);
    } else {
      if (mounted) setState(() => _unlocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) return const _SplashScreen();
    return const ItemListScreen();
  }
}

const String kPrivacySummary = '''
本应用承诺：所有物品数据仅存储于您的本地设备，不会自动上传至任何服务器。
使用条码扫描、附近设备同步等功能时，需您主动授权相应权限。
继续使用即表示您同意以下协议条款。''';

const String _docPrivacy = '''
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

const String _docTerms = '''
欢迎使用物品有效期管理工具。请您仔细阅读以下协议：

1. 服务说明
本应用是一款本地优先的物品有效期管理工具，提供物品信息录入、条码扫描、到期提醒等功能。所有数据默认存储于本地设备。

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

const String _docSdk = '''
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
