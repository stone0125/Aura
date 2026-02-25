import 'package:flutter/material.dart';
import 'habit_category.dart';

/// Form data for creating a new habit
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
  bool get hasValidIcon => selectedIcon != null;

  /// Get character count for name
  int get nameCharCount => name.length;

  /// Check if name is approaching limit
  bool get nameNearLimit => nameCharCount >= 40;

  /// Check if name exceeds limit
  bool get nameExceedsLimit => nameCharCount > 50;
}

/// Frequency type enumeration
enum FrequencyType {
  daily,
  weekly,
  custom,
}

/// Custom frequency unit
enum CustomFrequencyUnit {
  days,
  weeks,
  months,
}

/// Goal type enumeration
enum GoalType {
  none,
  time,
  count,
}

/// Notification style enumeration
enum NotificationStyle {
  standard,
  motivational,
  silent,
}

/// Extension for frequency type display
extension FrequencyTypeExtension on FrequencyType {
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
extension CustomFrequencyUnitExtension on CustomFrequencyUnit {
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
extension GoalTypeExtension on GoalType {
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
extension NotificationStyleExtension on NotificationStyle {
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
