import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/notification_messages.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // Request explicit permissions on iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }


  /// Schedule the 9:00 PM (21:00) daily reminder
  Future<void> scheduleDailyReminder({
    required bool Function() hasEntryToday,
    int hour = 21,
    int minute = 0,
  }) async {
    if (!_initialized) await init();

    try {
      // Cancel previous scheduled reminders
      await _notificationsPlugin.cancel(1001);

      // If user already logged today, skip scheduling for today, schedule for tomorrow
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      // If scheduled date passed or today is already logged, move to tomorrow
      if (scheduledDate.isBefore(now) || hasEntryToday()) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final message = NotificationMessages.getRandomMessage();

      await _notificationsPlugin.zonedSchedule(
        1001,
        'My Vibe 🌸',
        message,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_vibe_channel',
            'Daily Vibe Reminders',
            channelDescription: 'Nightly reminder to log your daily vibe emoji',
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Daily reminder scheduled for $scheduledDate with msg: $message');
    } catch (e) {
      debugPrint('Failed to schedule daily reminder: $e');
    }
  }

  /// Immediate test notification trigger for demonstration & user testing
  Future<void> showTestNotification() async {
    if (!_initialized) await init();

    final message = NotificationMessages.getRandomMessage();

    try {
      await _notificationsPlugin.show(
        9999,
        'My Vibe 🌸',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'vibe_test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications for Vibe Calendar',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Test notification error: $e');
    }
  }

  /// Show discreet notification when partner logs or updates a mood
  Future<void> showPartnerMoodNotification({
    required String partnerName,
  }) async {
    if (!_initialized) await init();

    const title = 'FT Vibe 🐰';
    final body = '$partnerName just logged a new vibe! Check it out 🌸';


    try {
      await _notificationsPlugin.show(
        2002,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'partner_vibe_channel',
            'FT Vibe Notifications',
            channelDescription: 'Notifications when your FT logs or updates their vibe',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Partner notification error: $e');
    }
  }


  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}

