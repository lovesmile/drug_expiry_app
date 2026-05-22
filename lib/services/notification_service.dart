import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/reminder_settings.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    _initialized = true;
  }

  static Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title ?? '到期提醒',
      body ?? '您有物品需要关注',
      const NotificationDetails(
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
      ),
      payload: payload,
    );
  }

  static Future<void> scheduleExpiryNotifications(ReminderSettings settings) async {
    if (settings.reminder30Days) {
      await showNotification(
        id: 30,
        title: '物品到期提醒',
        body: '部分物品将在 30 天内到期',
      );
    }

    if (settings.reminder7Days) {
      await showNotification(
        id: 7,
        title: '物品即将过期',
        body: '部分物品将在 7 天内过期',
      );
    }

    if (settings.reminder3Days) {
      await showNotification(
        id: 3,
        title: '物品即将过期',
        body: '部分物品将在 3 天内过期',
      );
    }

    if (settings.reminderExpired) {
      await showNotification(
        id: 0,
        title: '物品已过期',
        body: '部分物品已过期，请及时清理',
      );
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
