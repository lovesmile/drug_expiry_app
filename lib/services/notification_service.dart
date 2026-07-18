import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/item.dart';
import '../models/reminder_settings.dart';
import 'database_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      // 不在启动时弹通知授权对话框 —— 启动期 await 会卡住 Flutter
      // `_SplashScreen` 渲染，导致用户看到 native splash 的 launcher
      // icon 停留很久。改为懒授权：第一次真正发通知时再请求。
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    tz_data.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }

    _initialized = true;
  }

  static Future<bool> _ensurePermission() async {
    if (await Permission.notification.isGranted) return true;
    if (await Permission.notification.isPermanentlyDenied) return false;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'expiry_channel',
      '物品到期提醒',
      channelDescription: '物品有效期到期和即将到期通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// 立即弹出一条通知（调试/兜底用）
  static Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    if (!await _ensurePermission()) return;
    await _plugin.show(
      id,
      title ?? '到期提醒',
      body ?? '您有物品需要关注',
      _details,
      payload: payload,
    );
  }

  /// 从数据库读取全部物品与提醒设置，清空后按到期日重新排期。
  /// 增删改物品、修改提醒设置、以及 app 启动时调用。
  /// 任何内部异常都吃掉——release 包里 cancelAll() 在 R8 擦除 Gson 泛型
  /// 时会抛 "Missing type parameter"（flutter_local_notifications v18
  /// 已知问题）。吞掉后下次冷启动 / 下一笔变更时会重新尝试，闹钟不丢。
  static Future<void> rescheduleFromDb() async {
    try {
      if (!await _ensurePermission()) return;
      final db = DatabaseService();
      final items = await db.getAllItems();
      final s = await db.getReminderSettings();
      try {
        await _plugin.cancelAll();
      } catch (e) {
        // cancelAll 失败不阻塞新增闹钟；旧的依然能正常 trigger。
      }
      for (final item in items) {
        try {
          await _scheduleForItem(item, s);
        } catch (_) {}
      }
    } catch (_) {}
  }

  static Future<void> _scheduleForItem(Item item, ReminderSettings s) async {
    if (item.usageStatus != UsageStatus.active) return;
    final id = item.id;
    if (id == null) return;
    final deadline = item.deadlineDate;
    if (deadline == null) return;

    // (daysBefore, enabled, hh:mm, idOffset)
    final buckets = <(int, bool, String, int)>[
      (30, s.reminder30Days, s.time30Days, 1),
      (7, s.reminder7Days, s.time7Days, 2),
      (3, s.reminder3Days, s.time3Days, 3),
      (0, s.reminderExpired, s.timeExpired, 0),
    ];

    final now = tz.TZDateTime.now(tz.local);
    for (final (daysBefore, enabled, hhmm, offset) in buckets) {
      if (!enabled) continue;
      final fireAt = _fireAt(deadline, daysBefore, hhmm);
      if (!fireAt.isAfter(now)) continue; // 不补发过去的
      final (title, body) = _text(item.name, daysBefore);
      await _plugin.zonedSchedule(
        id * 10 + offset,
        title,
        body,
        fireAt,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static tz.TZDateTime _fireAt(DateTime deadline, int daysBefore, String hhmm) {
    final d = DateTime(deadline.year, deadline.month, deadline.day)
        .subtract(Duration(days: daysBefore));
    final p = hhmm.split(':');
    final h = int.tryParse(p.first) ?? 9;
    final m = p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0;
    return tz.TZDateTime(tz.local, d.year, d.month, d.day, h, m);
  }

  static bool get _isZh =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'zh';

  static (String, String) _text(String name, int daysBefore) {
    if (daysBefore == 0) {
      return _isZh
          ? ('物品已过期', '「$name」已到期，请及时处理')
          : ('Item expired', '"$name" has expired');
    }
    return _isZh
        ? ('物品即将到期', '「$name」将在 $daysBefore 天后到期')
        : ('Item expiring soon', '"$name" expires in $daysBefore day(s)');
  }

  static Future<int> pendingCount() async =>
      (await _plugin.pendingNotificationRequests()).length;

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
