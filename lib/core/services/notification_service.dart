import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Manages local push notifications and scheduled reminders.
///
/// Uses a singleton pattern to ensure only one instance manages
/// the notification plugin throughout the app lifecycle.
class NotificationService {
  static NotificationService? _instance;
  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initializes the notification plugin and requests permissions.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
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
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      // Request iOS permissions
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }

      // Request Android 13+ (API 33) POST_NOTIFICATIONS permission
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();
        }
      }

      _initialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Shows an immediate notification for group activity changes.
  ///
  /// Used when another member adds, updates, or deletes a plan or idea.
  Future<void> showGroupActivityNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'group_activity_channel',
            'Shared Calendar Updates',
            channelDescription:
                'Notifications when group members add or modify plans and ideas',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Failed to show group activity notification: $e');
    }
  }

  /// Schedules a future reminder notification for an upcoming event.
  ///
  /// The notification fires at [eventTime]. If [eventTime] is in the past,
  /// the scheduling is silently skipped.
  Future<void> scheduleActivityReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime eventTime,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    try {
      if (eventTime.isBefore(DateTime.now())) return;

      // Check if exact alarms are permitted on Android 12+
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final canSchedule =
              await androidPlugin.canScheduleExactNotifications() ?? false;
          if (!canSchedule) {
            debugPrint(
                'Cannot schedule exact alarms — permission not granted');
            return;
          }
        }
      }

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(eventTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders_channel',
            'Event Reminders',
            channelDescription: 'Reminders for planned group activities',
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
      );
    } catch (e) {
      debugPrint('Failed to schedule activity reminder: $e');
    }
  }

  /// Cancels all pending and shown notifications.
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel notifications: $e');
    }
  }
}
