import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'design/app_colors.dart';
import 'design/widgets/app_logo.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';
import 'providers/item_provider.dart';
import 'providers/family_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/item_list_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/webview_screen.dart';
import 'dart:async';

/// 全局唯一 ScaffoldMessenger 的 key。仅在主页显示的 fallback SnackBar 走这里；
/// 一旦 push 到其它路由，[HomeSnackBarHider] 会立刻把它 hide 掉。
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// 拦截 push/replace/pop 路由切换，离开首页时主动把主页的 fallback SnackBar 隐藏，
/// 否则全局 ScaffoldMessenger 会让 SnackBar 跟着新页面一起挂下来。
class HomeSnackBarHider extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }
}

void main() {
  // 启动期不阻塞 runApp：把 Firebase / 通知 / 广告初始化放到首帧后异步执行，
  // 否则 Firebase cold start + NotificationService.init + AdService.init 串起来
  // 在低端机可达 10s+，用户看到 splash 卡在 native 一段时间，影响启动体验。
  WidgetsFlutterBinding.ensureInitialized();
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
            title: '到期管家',
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            navigatorObservers: [HomeSnackBarHider()],
            supportedLocales: const [Locale('zh'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              ...GlobalMaterialLocalizations.delegates,
              GlobalWidgetsLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supported) {
              if (locale?.languageCode == 'zh') return const Locale('zh');
              return const Locale('en');
            },
            theme: AppTheme.build(
              brightness: Brightness.light,
              seed: settingsProvider.seedColor,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            darkTheme: AppTheme.build(
              brightness: Brightness.dark,
              seed: settingsProvider.seedColor,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            themeMode: settingsProvider.themeMode,
            builder: (context, child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppTheme.systemUiOverlayStyle(Theme.of(context).brightness),
                child: child ?? const SizedBox.shrink(),
              );
            },
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
    // 启动期重活延后到首帧之后；这里只注册 microtask，不等在 async 链上，
    // 让 _checkAgreed / setState 立即跑完，第一帧 UI 立即可见。
    Future<void>.microtask(_bootstrapBackgroundServices);
  }

  /// 后台初始化重活（fire-and-forget）。不返回 future 给 initState，
  /// 所有异常被吞掉，保证启动路径不被 Firebase / 通知 / 广告拖慢。
  Future<void> _bootstrapBackgroundServices() async {
    try {
      await Firebase.initializeApp();
      unawaited(FirebaseAnalytics.instance.logAppOpen().catchError((_) {}));
    } catch (_) {}
    // 50ms 让 UI 先完成首帧再启动通知 / 广告 init。
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      await NotificationService.init();
    } catch (_) {}
    try {
      await AdService.init();
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    // 启动期不显示 Flutter splash —— 避免和 Android 12+ native splash
    // 叠成"两个 splash"。直接让 native splash 的蓝底过渡到隐私协议页。
    if (_loading) return const SizedBox.shrink();
    if (_agreed) return _buildApp();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题区域
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                children: [
                  // 与 launcher / 启动页同一品牌标识，避免隐私协议页露馅灰色盒子。
                  const AppLogo(size: 72),
                  const SizedBox(height: 16),
                  Text(
                    '到期管家',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('v1.0.0', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            // 协议内容
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('welcome'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                      child: Text(context.tr('agree_continue'), style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600)),
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
      trailing: Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.outline),
      onTap: onTap,
    );
  }

  void _showPrivacy() => _openDoc(kUrlPrivacy, context.tr('view_privacy'));
  void _showTerms() => _openDoc(kUrlTerms, context.tr('view_terms'));
  void _showSdk() => _openDoc(kUrlSdk, context.tr('view_sdk'));

  Future<void> _openDoc(String url, String title) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => WebViewScreen(url: url, title: title)),
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
      // 固定品牌蓝，与 Android 原生 splash (colors.xml#2563EB) 接近，
      // 和 AppLogo 默认背景 (#2196F3) 也是同一色系：用户切换主题色
      // （绿/青）时启动瞬间不会闪一下变色的色块。
      backgroundColor: const Color(0xFF2563EB),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 72),
            const SizedBox(height: 16),
            const Text(
              '到期管家',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'v1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 32),
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
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    // Settings 已在到达此 gate 前加载完成：同步判断是否需要锁屏。
    // 锁未开启时立即放行，避免多余的 v1.0.0 splash 一闪而过。
    final settings = context.read<SettingsProvider>();
    if (settings.appLockEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _promptLock());
    } else {
      _unlocked = true;
    }
  }

  Future<void> _promptLock() async {
    if (!mounted) return;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LockScreen(), fullscreenDialog: true),
    );
    if (mounted) setState(() => _unlocked = ok == true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) return const _SplashScreen();
    return const ItemListScreen();
  }
}

const String kPrivacySummary = '''
本应用承诺：所有物品数据仅存储于您的本地设备，不会自动上传至任何服务器。
使用条码扫描、附近设备同步、应用锁、到期提醒等功能时，需您主动授权相应权限。
继续使用即表示您同意以下协议条款。''';

const String kUrlPrivacy =
    'https://lovesmile.github.io/expiry-tracker-privacy/index.html';
const String kUrlTerms =
    'https://lovesmile.github.io/expiry-tracker-privacy/terms.html';
const String kUrlSdk =
    'https://lovesmile.github.io/expiry-tracker-privacy/sdk.html';
