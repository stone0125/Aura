// =============================================================================
// notification_service.dart — Notification Service
// 通知服务
//
// Manages both local notifications and Firebase Cloud Messaging (FCM):
// - Schedule daily habit reminders at user-specified times
// - Handle push notifications from Firebase
// - Manage iOS app icon badge count
// - Daily summary notifications
// Uses singleton pattern to ensure single instance across the app.
//
// 管理本地通知和 Firebase 云消息（FCM）：
// - 按用户指定时间安排每日习惯提醒
// - 处理来自 Firebase 的推送通知
// - 管理 iOS 应用图标角标数量
// - 每日摘要通知
// 使用单例模式确保应用中只有一个实例。
// =============================================================================

import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'firestore_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/habit.dart';

/// Handle Firebase messages received while the app is in the background
/// 处理应用在后台时收到的 Firebase 消息
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  /// Factory constructor returning the singleton instance
  /// 工厂构造函数，返回单例实例
  factory NotificationService() => _instance;

  /// Private internal constructor for singleton pattern
  /// 单例模式的私有内部构造函数
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final fln.FlutterLocalNotificationsPlugin _localNotifications =
      fln.FlutterLocalNotificationsPlugin();

  int _currentBadgeCount = 0;

  /// Stream subscriptions for Firebase messaging - must be disposed
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  bool _isInitialized = false;

  /// Counter for generating unique notification IDs for immediate notifications
  /// Using timestamp + counter to ensure uniqueness even in rapid succession
  int _notificationCounter = 0;

  /// Generates a unique notification ID for immediate (non-scheduled) notifications.
  /// 为即时（非定时）通知生成唯一的通知 ID。
  /// Uses timestamp combined with a counter to avoid collisions.
  /// 使用时间戳结合计数器以避免冲突。
  int _generateUniqueNotificationId() {
    _notificationCounter = (_notificationCounter + 1) % 10000;
    // Use milliseconds mod a large prime, offset by counter
    // This gives us ~2 billion unique values before potential collision
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return ((timestamp % 2147483647) + _notificationCounter) % 2147483647;
  }

  /// Generates a deterministic notification ID from a habit ID.
  /// 根据习惯 ID 生成确定性的通知 ID。
  /// Uses a better distribution than simple hashCode % small number.
  /// 使用比简单 hashCode % 小数更好的分布方式。
  int _habitIdToNotificationId(String habitId) {
    // Use hashCode but spread across full 32-bit positive range
    // This gives ~2 billion possible IDs instead of just 100,000
    return habitId.hashCode.abs() % 2147483647;
  }

  /// Validates that a payload is a legitimate habit ID (alphanumeric/UUID format)
  /// 验证 payload 是否为合法的习惯 ID（字母数字/UUID 格式）
  bool _isValidHabitId(String payload) {
    // Habit IDs are typically UUIDs or alphanumeric strings
    // Reject anything that looks like a path or URL
    if (payload.contains('/') ||
        payload.contains('\\') ||
        payload.contains(':') ||
        payload.contains('..') ||
        payload.startsWith('http')) {
      return false;
    }
    // Allow alphanumeric, hyphens, and underscores (typical ID formats)
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(payload);
  }

  /// Initialize the notification service (timezone, permissions, FCM, local notifications)
  /// 初始化通知服务（时区、权限、FCM、本地通知）
  Future<void> initialize() async {
    // Prevent double initialization
    if (_isInitialized) {
      debugPrint('NotificationService already initialized, skipping');
      return;
    }

    // Initialize Time Zones with error handling
    tz.initializeTimeZones();
    try {
      final rawTimezone = await FlutterTimezone.getLocalTimezone();
      // Extract IANA timezone name - handle cases where toString() wraps it
      // e.g. "TimezoneInfo(Asia/Kuala_Lumpur, ...)" -> "Asia/Kuala_Lumpur"
      String timeZoneName = rawTimezone.toString();
      final match = RegExp(r'TimezoneInfo\(([^,]+)').firstMatch(timeZoneName);
      if (match != null) {
        timeZoneName = match.group(1)!.trim();
      }
      // Validate timezone name before using it
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('Timezone set to: $timeZoneName');
      } catch (_) {
        debugPrint(
          'WARNING: Invalid timezone name "$timeZoneName", falling back to UTC. Notifications will use UTC times.',
        );
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      debugPrint(
        'WARNING: Failed to detect timezone, falling back to UTC: $e. Notifications will use UTC times.',
      );
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Request permissions (Remote & Local)
    await _requestPermission();

    // Initialize local notifications
    const androidSettings = fln.AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = fln.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse details) {
        // Handle notification tap
        debugPrint('Notification tapped');
        if (details.payload != null) {
          // Security: Only handle known safe payload types
          // Whitelist: habit IDs, daily_summary, or other known identifiers
          final payload = details.payload!;

          // Whitelist of safe payload patterns
          if (payload == 'daily_summary' ||
              payload == 'export_complete' ||
              _isValidHabitId(payload)) {
            // Safe payload - can be used for navigation
            debugPrint('Valid notification payload received');
          } else {
            // Reject potentially dangerous payloads (file paths, URLs, etc.)
            debugPrint('Security: Rejected unknown notification payload type');
          }
        }
      },
    );

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground handler - store subscription for disposal
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message);
      }
    });

    // Get FCM token (with timeout — hangs on devices without Google Play Services)
    try {
      final token = await _firebaseMessaging.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (token != null) {
        debugPrint('FCM Token obtained successfully');
        await FirestoreService().saveDeviceToken(token);
      } else {
        debugPrint(
          'FCM Token not available (no Google Play Services or timeout)',
        );
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // Listen for default token refresh - store subscription for disposal
    _onTokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((
      token,
    ) async {
      debugPrint('FCM Token refreshed');
      await FirestoreService().saveDeviceToken(token);
    });

    // Clear badge on app launch
    await clearBadge();

    _isInitialized = true;
    debugPrint('NotificationService initialized successfully');
  }

  /// Dispose of stream subscriptions to prevent memory leaks
  /// 释放流订阅以防止内存泄漏
  /// Call this when the app is being destroyed or the service is no longer needed
  /// 在应用销毁或不再需要服务时调用
  Future<void> dispose() async {
    await _onMessageSubscription?.cancel();
    _onMessageSubscription = null;
    await _onTokenRefreshSubscription?.cancel();
    _onTokenRefreshSubscription = null;
    _isInitialized = false;
    debugPrint('NotificationService disposed');
  }

  /// Request notification permissions for FCM and local notifications
  /// 请求 FCM 和本地通知的通知权限
  Future<void> _requestPermission() async {
    try {
      // 1. Request FCM Permission (iOS prompts here)
      final NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);
      debugPrint(
        'User granted FCM permission: ${settings.authorizationStatus}',
      );

      // 2. Request Android Local Notifications Permission (Android 13+)
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<
              fln.AndroidFlutterLocalNotificationsPlugin
            >();

        final bool? grantedMessages = await androidImplementation
            ?.requestNotificationsPermission();
        debugPrint('Android Notification Permission: $grantedMessages');

        final bool? grantedAlarms = await androidImplementation
            ?.requestExactAlarmsPermission();
        debugPrint('Android Exact Alarm Permission: $grantedAlarms');
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  /// Set app badge count (iOS only)
  /// 设置应用角标数量（仅限 iOS）
  /// Uses a silent notification to update the badge number
  /// 使用静默通知更新角标数字
  Future<void> setBadgeCount(int count) async {
    _currentBadgeCount = count;

    if (!kIsWeb && Platform.isIOS) {
      try {
        // On iOS, we update the badge by showing a silent notification with the badge number
        // or by using the notification plugin's iOS-specific badge setting
        final iosPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              fln.IOSFlutterLocalNotificationsPlugin
            >();

        if (iosPlugin != null) {
          // Show a silent notification that only updates the badge
          await _localNotifications.show(
            0, // Use ID 0 for badge-only updates
            null, // No title (silent)
            null, // No body (silent)
            fln.NotificationDetails(
              iOS: fln.DarwinNotificationDetails(
                presentAlert: false,
                presentSound: false,
                presentBadge: true,
                badgeNumber: count > 0 ? count : null,
              ),
            ),
          );
          // Cancel it immediately since we just wanted to update badge
          if (count == 0) {
            await _localNotifications.cancel(0);
          }
        }
        debugPrint('iOS badge set to: $count');
      } catch (e) {
        debugPrint('Error setting iOS badge: $e');
      }
    }

    debugPrint('Badge count set to: $count');
  }

  /// Clear app badge (iOS)
  /// 清除应用角标（iOS）
  Future<void> clearBadge() async {
    _currentBadgeCount = 0;

    if (!kIsWeb && Platform.isIOS) {
      try {
        // Only cancel the badge notification (ID 0), not all scheduled reminders
        await _localNotifications.cancel(0);
        debugPrint('iOS badge cleared');
      } catch (e) {
        debugPrint('Error clearing iOS badge: $e');
      }
    }

    debugPrint('Badge cleared');
  }

  /// Get current badge count
  /// 获取当前角标数量
  int get currentBadgeCount => _currentBadgeCount;

  /// Show a local notification from a Firebase remote message
  /// 根据 Firebase 远程消息显示本地通知
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        _generateUniqueNotificationId(),
        notification.title,
        notification.body,
        fln.NotificationDetails(
          android: const fln.AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(
            badgeNumber: _currentBadgeCount > 0 ? _currentBadgeCount : null,
          ),
        ),
      );
    }
  }

  /// Show a habit reminder notification
  /// 显示习惯提醒通知
  Future<void> showHabitReminder({
    required String title,
    required String body,
    int? badgeCount,
  }) async {
    if (badgeCount != null) {
      _currentBadgeCount = badgeCount;
    }

    final notificationId = _generateUniqueNotificationId();
    await _localNotifications.show(
      notificationId,
      title,
      body,
      fln.NotificationDetails(
        android: const fln.AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Reminders for your daily habits',
          importance: fln.Importance.high,
          priority: fln.Priority.high,
        ),
        iOS: fln.DarwinNotificationDetails(
          badgeNumber: _currentBadgeCount > 0 ? _currentBadgeCount : null,
        ),
      ),
    );
  }

  /// Schedule a daily habit reminder
  /// 安排每日习惯提醒
  /// [habitId] is used as the notification ID for cancellation
  /// [habitId] 用作取消通知的通知 ID
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    // Generate a deterministic notification ID from habit ID
    final notificationId = _habitIdToNotificationId(habitId);

    // Cancel any existing reminder for this habit
    await cancelHabitReminder(habitId);

    // Calculate schedule time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Schedule exact daily reminder
    try {
      await _localNotifications.zonedSchedule(
        notificationId,
        'Time for: $habitName',
        "Don't forget to complete your habit today! 💪",
        scheduledDate,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Daily reminders for your habits',
            importance: fln.Importance.high,
            priority: fln.Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: fln.DateTimeComponents.time,
        payload: habitId,
      );

      debugPrint(
        'Scheduled reminder for $habitName at $hour:$minute (ID: $notificationId, scheduledFor: $scheduledDate)',
      );
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
    }
  }

  /// Show a generic notification immediately
  /// 立即显示一条通用通知
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final notificationId = _generateUniqueNotificationId();
      await _localNotifications.show(
        notificationId,
        title,
        body,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'general_notifications',
            'General Notifications',
            channelDescription: 'General app notifications',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      debugPrint('Notification shown: $title');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Show a test notification immediately (for debugging)
  /// 立即显示测试通知（用于调试）
  Future<void> showTestNotification() async {
    try {
      await _localNotifications.show(
        999,
        '🔔 Test Notification',
        'If you see this, notifications are working!',
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Daily reminders for your habits',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('Test notification sent successfully!');
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }

  /// Show test daily summary notification immediately (for debugging)
  /// 立即显示测试每日摘要通知（用于调试）
  Future<void> showTestDailySummary(int habitCount) async {
    try {
      final hour = DateTime.now().hour;
      String title;
      if (hour < 12) {
        title = 'Good morning! ☀️';
      } else if (hour < 17) {
        title = 'Good afternoon! 👋';
      } else {
        title = 'Good evening! 🌙';
      }

      String body;
      if (habitCount == 0) {
        body = "You're all caught up! No habits to complete today.";
      } else if (habitCount == 1) {
        body = "You have 1 habit to complete today. Let's do it! 💪";
      } else {
        body = "You have $habitCount habits to complete today. Let's go! 💪";
      }

      await _localNotifications.show(
        998,
        title,
        body,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'daily_summary',
            'Daily Summary',
            channelDescription: 'Daily summary of your habits',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint(
        'Test daily summary sent successfully! (habitCount: $habitCount)',
      );
    } catch (e) {
      debugPrint('Error showing test daily summary: $e');
    }
  }

  /// Cancel a scheduled habit reminder
  /// 取消已安排的习惯提醒
  Future<void> cancelHabitReminder(String habitId) async {
    final notificationId = _habitIdToNotificationId(habitId);
    await _localNotifications.cancel(notificationId);
    debugPrint(
      'Cancelled reminder for habit ID: $habitId (ID: $notificationId)',
    );
  }

  /// Reset state on logout to prevent cross-user data leaks
  /// 登出时重置状态以防止跨用户数据泄漏
  void resetOnLogout() {
    _currentBadgeCount = 0;
  }

  /// Cancel all scheduled reminders
  /// 取消所有已安排的提醒
  Future<void> cancelAllReminders() async {
    await _localNotifications.cancelAll();
    debugPrint('Cancelled all reminders');
  }

  /// Schedule reminders for multiple habits (parallel execution)
  /// 为多个习惯安排提醒（并行执行）
  Future<void> scheduleAllHabitReminders(List<Habit> habits) async {
    // Filter habits with reminders enabled and schedule in parallel
    final reminderFutures = habits
        .where((habit) => habit.reminderEnabled && habit.reminderTime != null)
        .map(
          (habit) => scheduleHabitReminder(
            habitId: habit.id,
            habitName: habit.name,
            hour: habit.reminderTime!.hour,
            minute: habit.reminderTime!.minute,
          ),
        )
        .toList();

    await Future.wait(reminderFutures);
  }

  // ==================== Daily Summary Notification ====================

  static const int _dailySummaryNotificationId = 1000;

  /// Schedule a daily summary notification
  /// 安排每日摘要通知
  /// Shows a motivational message at the set time
  /// 在设定时间显示激励消息
  Future<void> scheduleDailySummary({
    required int hour,
    required int minute,
  }) async {
    // Cancel existing daily summary first
    await cancelDailySummary();

    // Calculate schedule time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Build motivational message based on time of day
    String title;
    String body;

    if (hour < 12) {
      title = 'Good morning! ☀️';
      body = 'Rise and shine! Time to build great habits today.';
    } else if (hour < 17) {
      title = 'Good afternoon! 👋';
      body = 'Check in on your habits. Keep the momentum going!';
    } else {
      title = 'Good evening! 🌙';
      body = 'How did your habits go today? Take a moment to review.';
    }

    try {
      await _localNotifications.zonedSchedule(
        _dailySummaryNotificationId,
        title,
        body,
        scheduledDate,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'daily_summary',
            'Daily Summary',
            channelDescription: 'Daily summary of your habits',
            importance: fln.Importance.high,
            priority: fln.Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: fln.DateTimeComponents.time,
        payload: 'daily_summary',
      );

      debugPrint(
        'Scheduled daily summary at $hour:$minute (next: $scheduledDate)',
      );
    } catch (e) {
      debugPrint('Error scheduling daily summary: $e');
    }
  }

  /// Cancel the daily summary notification
  /// 取消每日摘要通知
  Future<void> cancelDailySummary() async {
    await _localNotifications.cancel(_dailySummaryNotificationId);
    debugPrint('Cancelled daily summary notification');
  }
}
