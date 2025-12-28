import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  int _currentBadgeCount = 0;

  Future<void> initialize() async {
    // Request permission
    await _requestPermission();

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message);
      }
    });

    // Get token
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      if (token != null) {
        await FirestoreService().saveDeviceToken(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      debugPrint('FCM Token Refreshed: $token');
      FirestoreService().saveDeviceToken(token);
    });

    // Clear badge on app launch
    await clearBadge();
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  /// Set app badge count (iOS only)
  Future<void> setBadgeCount(int count) async {
    _currentBadgeCount = count;

    if (Platform.isIOS) {
      try {
        debugPrint('iOS badge set to: $count');
      } catch (e) {
        debugPrint('Error setting iOS badge: $e');
      }
    }

    debugPrint('Badge count set to: $count');
  }

  /// Clear app badge (iOS)
  Future<void> clearBadge() async {
    _currentBadgeCount = 0;

    if (Platform.isIOS) {
      try {
        // Clearing notifications also clears the badge on iOS
        await _localNotifications.cancelAll();
        debugPrint('iOS badge cleared');
      } catch (e) {
        debugPrint('Error clearing iOS badge: $e');
      }
    }

    debugPrint('Badge cleared');
  }

  /// Get current badge count
  int get currentBadgeCount => _currentBadgeCount;

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            badgeNumber: _currentBadgeCount > 0 ? _currentBadgeCount : null,
          ),
        ),
      );
    }
  }

  /// Show a habit reminder notification
  Future<void> showHabitReminder({
    required String title,
    required String body,
    int? badgeCount,
  }) async {
    if (badgeCount != null) {
      _currentBadgeCount = badgeCount;
    }

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Reminders for your daily habits',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          badgeNumber: _currentBadgeCount > 0 ? _currentBadgeCount : null,
        ),
      ),
    );
  }

  /// Schedule a daily habit reminder
  /// [habitId] is used as the notification ID for cancellation
  /// [time] is the time of day to send the reminder
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    // Generate a unique notification ID from habit ID
    final notificationId = habitId.hashCode.abs() % 100000;

    // Cancel any existing reminder for this habit
    await cancelHabitReminder(habitId);

    // Schedule daily repeating notification
    await _localNotifications.periodicallyShow(
      notificationId,
      'Time for: $habitName',
      "Don't forget to complete your habit today! 💪",
      RepeatInterval.daily,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Daily reminders for your habits',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: habitId,
    );

    debugPrint(
      'Scheduled reminder for $habitName at $hour:$minute (ID: $notificationId)',
    );
  }

  /// Cancel a scheduled habit reminder
  Future<void> cancelHabitReminder(String habitId) async {
    final notificationId = habitId.hashCode.abs() % 100000;
    await _localNotifications.cancel(notificationId);
    debugPrint(
      'Cancelled reminder for habit ID: $habitId (ID: $notificationId)',
    );
  }

  /// Cancel all scheduled reminders
  Future<void> cancelAllReminders() async {
    await _localNotifications.cancelAll();
    debugPrint('Cancelled all reminders');
  }

  /// Schedule reminders for multiple habits
  Future<void> scheduleAllHabitReminders(List<dynamic> habits) async {
    for (final habit in habits) {
      if (habit.reminderEnabled && habit.reminderTime != null) {
        await scheduleHabitReminder(
          habitId: habit.id,
          habitName: habit.name,
          hour: habit.reminderTime.hour,
          minute: habit.reminderTime.minute,
        );
      }
    }
  }
}
