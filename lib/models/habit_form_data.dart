// =============================================================================
// habit_form_data.dart — Habit Creation/Editing Form Data
// 习惯创建/编辑表单数据
//
// Mutable form data class used by the habit creation and editing screens.
// Holds all user input: name, description, category, icon, frequency type
// (daily/weekly/custom), goal settings, and reminder configuration.
//
// 习惯创建和编辑界面使用的可变表单数据类。
// 保存所有用户输入：名称、描述、类别、图标、频率类型
// （每日/每周/自定义）、目标设置和提醒配置。
// =============================================================================

import 'package:flutter/material.dart';
import 'habit_category.dart';

/// Form data for creating a new habit
/// 创建新习惯的表单数据
class HabitFormData {
  String name;
  String description;
  HabitCategory? category;
  IconData? selectedIcon;
  FrequencyType frequencyType;
  List<int> weeklyDays; // 0=Sunday, 1=Monday, ..., 6=Saturday
  int customInterval;
  CustomFrequencyUnit customUnit;
  GoalType goalType;
  int? goalValue;
  String? goalUnit;
  bool reminderEnabled;
  TimeOfDay reminderTime;
  bool aiOptimizedTiming;
  NotificationStyle notificationStyle;
  bool isAISuggested;

  /// Creates a HabitFormData with default values for all fields
  /// 使用所有字段的默认值创建 HabitFormData
  HabitFormData({
    this.name = '',
    this.description = '',
    this.category,
    this.selectedIcon,
    this.frequencyType = FrequencyType.daily,
    List<int>? weeklyDays,
    this.customInterval = 1,
    this.customUnit = CustomFrequencyUnit.days,
    this.goalType = GoalType.none,
    this.goalValue,
    this.goalUnit,
    this.reminderEnabled = false,
    this.reminderTime = const TimeOfDay(hour: 9, minute: 0),
    this.aiOptimizedTiming = false,
    this.notificationStyle = NotificationStyle.standard,
    this.isAISuggested = false,
  }) : weeklyDays = weeklyDays ?? [];

  /// Check if form is valid
  /// 检查表单是否有效
  bool get isValid {
    if (name.isEmpty || name.length > 50) return false;
    if (category == null) return false;
    if (frequencyType == FrequencyType.weekly && weeklyDays.isEmpty) {
      return false;
    }
    if (frequencyType == FrequencyType.custom && customInterval <= 0) {
      return false;
    }
    // Validate goal: if a goal type is set, value must be positive
    if (goalType != GoalType.none && (goalValue == null || goalValue! <= 0)) {
      return false;
    }
    // Validate reminder time bounds if reminders are enabled
    if (reminderEnabled) {
      if (reminderTime.hour < 0 || reminderTime.hour > 23) return false;
      if (reminderTime.minute < 0 || reminderTime.minute > 59) return false;
    }
    return true;
  }

  /// Check if icon is selected (has a valid icon)
  /// 检查是否已选择图标（是否有有效图标）
  bool get hasValidIcon => selectedIcon != null;

  /// Get character count for name
  /// 获取名称的字符数
  int get nameCharCount => name.length;

  /// Check if name is approaching limit
  /// 检查名称是否接近字数上限
  bool get nameNearLimit => nameCharCount >= 40;

  /// Check if name exceeds limit
  /// 检查名称是否超过字数上限
  bool get nameExceedsLimit => nameCharCount > 50;
}

/// Frequency type enumeration
/// 频率类型枚举
enum FrequencyType {
  daily,
  weekly,
  custom,
}

/// Custom frequency unit
/// 自定义频率单位
enum CustomFrequencyUnit {
  days,
  weeks,
  months,
}

/// Goal type enumeration
/// 目标类型枚举
enum GoalType {
  none,
  time,
  count,
}

/// Notification style enumeration
/// 通知样式枚举
enum NotificationStyle {
  standard,
  motivational,
  silent,
}

/// Extension for frequency type display
/// 频率类型显示扩展
extension FrequencyTypeExtension on FrequencyType {
  /// Get display name for the frequency type
  /// 获取频率类型的显示名称
  String get displayName {
    switch (this) {
      case FrequencyType.daily:
        return 'Daily';
      case FrequencyType.weekly:
        return 'Weekly';
      case FrequencyType.custom:
        return 'Custom';
    }
  }
}

/// Extension for custom frequency unit display
/// 自定义频率单位显示扩展
extension CustomFrequencyUnitExtension on CustomFrequencyUnit {
  /// Get display name for the frequency unit
  /// 获取频率单位的显示名称
  String get displayName {
    switch (this) {
      case CustomFrequencyUnit.days:
        return 'days';
      case CustomFrequencyUnit.weeks:
        return 'weeks';
      case CustomFrequencyUnit.months:
        return 'months';
    }
  }
}

/// Extension for goal type display
/// 目标类型显示扩展
extension GoalTypeExtension on GoalType {
  /// Get display name for the goal type
  /// 获取目标类型的显示名称
  String get displayName {
    switch (this) {
      case GoalType.none:
        return 'None';
      case GoalType.time:
        return 'Time-based';
      case GoalType.count:
        return 'Count-based';
    }
  }
}

/// Extension for notification style display
/// 通知样式显示扩展
extension NotificationStyleExtension on NotificationStyle {
  /// Get display name for the notification style
  /// 获取通知样式的显示名称
  String get displayName {
    switch (this) {
      case NotificationStyle.standard:
        return 'Standard notification';
      case NotificationStyle.motivational:
        return 'Motivational message (AI-generated)';
      case NotificationStyle.silent:
        return 'Silent (badge only)';
    }
  }
}
