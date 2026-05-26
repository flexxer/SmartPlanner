import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_planner/features/notifications/notification_channels.dart';
import 'package:timezone/timezone.dart' as tz;

/// Initializes and schedules local push notifications.
class NotificationHelper {
  NotificationHelper._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    await _createAndroidChannels();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  static Future<void> _createAndroidChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return;
    }

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        NotificationChannels.meetings,
        'notification_meetings_channel'.tr(),
        description: 'notification_meetings_channel_desc'.tr(),
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        NotificationChannels.taskDigest,
        'notification_digest_channel'.tr(),
        description: 'notification_digest_channel_desc'.tr(),
        importance: Importance.defaultImportance,
      ),
    );
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        NotificationChannels.overdueTasks,
        'notification_overdue_channel'.tr(),
        description: 'notification_overdue_channel_desc'.tr(),
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        NotificationChannels.dayStatus,
        'notification_day_status_channel'.tr(),
        description: 'notification_day_status_channel_desc'.tr(),
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );
  }

  /// Schedules a one-shot notification (meeting, digest, etc.).
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String channelId,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      NotificationChannels.meetings,
      'notification_reminders_group'.tr(),
      importance: Importance.high,
      priority: Priority.high,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<void> cancelAll() => _plugin.cancelAll();
}
