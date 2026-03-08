// =============================================================================
// settings_models.dart — Settings & User Profile Models
// 设置与用户资料模型
//
// Data classes for user settings and profile management. UserProfile stores
// account info (name, email, avatar, membership). UserSettings holds
// preferences for theme mode, notifications, and text size.
// Used by SettingsProvider and the settings screen.
//
// 用户设置和资料管理的数据类。UserProfile 存储账户信息
// （姓名、邮箱、头像、会员状态）。UserSettings 保存
// 主题模式、通知和字体大小的偏好设置。
// 由 SettingsProvider 和设置界面使用。
// =============================================================================

import 'package:flutter/material.dart';

/// User profile data
class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final DateTime memberSince;
  final bool isPro;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.displayName,
    this.bio,
    this.avatarUrl,
    required this.memberSince,
    this.isPro = false,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return (first + last).toUpperCase();
  }

  String get memberSinceText {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    // Ensure month is within valid range (1-12)
    final monthIndex = memberSince.month;
    if (monthIndex < 1 || monthIndex > 12) {
      return 'Member since ${memberSince.year}';
    }
    return 'Member since ${months[monthIndex - 1]} ${memberSince.year}';
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isPro,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberSince: memberSince,
      isPro: isPro ?? this.isPro,
    );
  }
}

/// Theme preference
enum ThemePreference {
  light,
  dark,
  system,
}

extension ThemePreferenceExtension on ThemePreference {
  String get displayName {
    switch (this) {
      case ThemePreference.light:
        return 'Light';
      case ThemePreference.dark:
        return 'Dark';
      case ThemePreference.system:
        return 'System';
    }
  }
}

/// Notification frequency
enum NotificationFrequency {
  daily,
  weekly,
  biweekly,
  onDemand,
}

extension NotificationFrequencyExtension on NotificationFrequency {
  String get displayName {
    switch (this) {
      case NotificationFrequency.daily:
        return 'Daily';
      case NotificationFrequency.weekly:
        return 'Weekly';
      case NotificationFrequency.biweekly:
        return 'Bi-weekly';
      case NotificationFrequency.onDemand:
        return 'On-demand only';
    }
  }

  String get description {
    switch (this) {
      case NotificationFrequency.daily:
        return 'Every morning';
      case NotificationFrequency.weekly:
        return 'Every Sunday';
      case NotificationFrequency.biweekly:
        return 'Every 2 weeks';
      case NotificationFrequency.onDemand:
        return 'User-initiated only';
    }
  }
}

/// Text size preference
enum TextSizePreference {
  system,
  small,
  medium,
  large,
  extraLarge,
}

extension TextSizePreferenceExtension on TextSizePreference {
  String get displayName {
    switch (this) {
      case TextSizePreference.system:
        return 'System';
      case TextSizePreference.small:
        return 'Small';
      case TextSizePreference.medium:
        return 'Medium';
      case TextSizePreference.large:
        return 'Large';
      case TextSizePreference.extraLarge:
        return 'Extra Large';
    }
  }

  double get scale {
    switch (this) {
      case TextSizePreference.system:
        return 1.0;
      case TextSizePreference.small:
        return 0.9;
      case TextSizePreference.medium:
        return 1.0;
      case TextSizePreference.large:
        return 1.1;
      case TextSizePreference.extraLarge:
        return 1.2;
    }
  }
}

/// Export format
enum ExportFormat {
  csv,
  json,
  pdf,
}

extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.csv:
        return 'CSV (Spreadsheet)';
      case ExportFormat.json:
        return 'JSON (Developer)';
      case ExportFormat.pdf:
        return 'PDF (Report)';
    }
  }

  String get description {
    switch (this) {
      case ExportFormat.csv:
        return 'Open in Excel, Google Sheets';
      case ExportFormat.json:
        return 'For developers and integrations';
      case ExportFormat.pdf:
        return 'Formatted report with charts';
    }
  }

  IconData get icon {
    switch (this) {
      case ExportFormat.csv:
        return Icons.table_chart_rounded;
      case ExportFormat.json:
        return Icons.code_rounded;
      case ExportFormat.pdf:
        return Icons.description_rounded;
    }
  }
}

/// Sync status
enum SyncStatus {
  synced,
  syncing,
  offline,
  error,
}

extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.error:
        return 'Sync failed';
    }
  }

  Color getColor(bool isDark) {
    switch (this) {
      case SyncStatus.synced:
        return isDark ? const Color(0xFF69F0AE) : const Color(0xFF27AE60);
      case SyncStatus.syncing:
        return isDark ? const Color(0xFF82B1FF) : const Color(0xFF2196F3);
      case SyncStatus.offline:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF39C12);
      case SyncStatus.error:
        return isDark ? const Color(0xFFFF5252) : const Color(0xFFE74C3C);
    }
  }

  IconData get icon {
    switch (this) {
      case SyncStatus.synced:
        return Icons.check_circle_rounded;
      case SyncStatus.syncing:
        return Icons.sync_rounded;
      case SyncStatus.offline:
        return Icons.cloud_off_rounded;
      case SyncStatus.error:
        return Icons.error_rounded;
    }
  }
}

/// App settings state
class AppSettings {
  final ThemePreference themePreference;
  final bool notificationsEnabled;
  final TimeOfDay defaultReminderTime;
  final String notificationSound;
  final bool badgeEnabled;
  final bool motivationalMessages;
  final bool aiSuggestionsEnabled;
  final NotificationFrequency suggestionFrequency;
  final bool aiOptimizedReminders;
  final bool shareDataForAI;
  final bool cloudSyncEnabled;
  final SyncStatus syncStatus;
  final DateTime? lastSyncTime;
  final bool autoBackupEnabled;
  final TextSizePreference textSize;
  final bool reduceMotion;
  final bool colorBlindMode;

  const AppSettings({
    this.themePreference = ThemePreference.system,
    this.notificationsEnabled = true,
    this.defaultReminderTime = const TimeOfDay(hour: 9, minute: 0),
    this.notificationSound = 'Default',
    this.badgeEnabled = true,
    this.motivationalMessages = true,
    this.aiSuggestionsEnabled = true,
    this.suggestionFrequency = NotificationFrequency.weekly,
    this.aiOptimizedReminders = false,
    this.shareDataForAI = false,
    this.cloudSyncEnabled = false,
    this.syncStatus = SyncStatus.offline,
    this.lastSyncTime,
    this.autoBackupEnabled = false,
    this.textSize = TextSizePreference.system,
    this.reduceMotion = false,
    this.colorBlindMode = false,
  });

  String get reminderTimeText {
    final hour = defaultReminderTime.hour;
    final minute = defaultReminderTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String? get lastSyncText {
    if (lastSyncTime == null) return null;
    final now = DateTime.now();
    final diff = now.difference(lastSyncTime!);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  AppSettings copyWith({
    ThemePreference? themePreference,
    bool? notificationsEnabled,
    TimeOfDay? defaultReminderTime,
    String? notificationSound,
    bool? badgeEnabled,
    bool? motivationalMessages,
    bool? aiSuggestionsEnabled,
    NotificationFrequency? suggestionFrequency,
    bool? aiOptimizedReminders,
    bool? shareDataForAI,
    bool? cloudSyncEnabled,
    SyncStatus? syncStatus,
    DateTime? lastSyncTime,
    bool? autoBackupEnabled,
    TextSizePreference? textSize,
    bool? reduceMotion,
    bool? colorBlindMode,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultReminderTime: defaultReminderTime ?? this.defaultReminderTime,
      notificationSound: notificationSound ?? this.notificationSound,
      badgeEnabled: badgeEnabled ?? this.badgeEnabled,
      motivationalMessages: motivationalMessages ?? this.motivationalMessages,
      aiSuggestionsEnabled: aiSuggestionsEnabled ?? this.aiSuggestionsEnabled,
      suggestionFrequency: suggestionFrequency ?? this.suggestionFrequency,
      aiOptimizedReminders: aiOptimizedReminders ?? this.aiOptimizedReminders,
      shareDataForAI: shareDataForAI ?? this.shareDataForAI,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      textSize: textSize ?? this.textSize,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      colorBlindMode: colorBlindMode ?? this.colorBlindMode,
    );
  }
}
