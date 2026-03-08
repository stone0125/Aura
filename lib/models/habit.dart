// =============================================================================
// habit.dart — Habit Data Model
// 习惯数据模型
//
// Defines the Habit class — the core data entity of the app. Each habit has
// a name, category, streak count, completion status, goal settings, and
// reminder settings. Uses copyWith pattern for immutable updates.
//
// 定义 Habit 类——应用的核心数据实体。每个习惯包含名称、类别、连续天数、
// 完成状态、目标设置和提醒设置。使用 copyWith 模式实现不可变更新。
// =============================================================================

import 'package:flutter/material.dart';
import 'habit_category.dart';

/// Habit model representing a user's habit
/// 表示用户习惯的习惯模型
class Habit {
  final String id;
  final String name;
  final HabitCategory category;
  final int streak;
  final bool isCompleted;
  final DateTime? lastCompletedDate;

  // Goal settings
  final String goalType; // 'none', 'time', 'count'
  final int? goalValue;
  final String? goalUnit; // 'minutes', 'hours', 'times', 'pages', etc.

  // Reminder settings
  final bool reminderEnabled;
  final TimeOfDay? reminderTime;
  final DateTime? createdAt;

  /// Creates a Habit instance with the given properties
  /// 使用给定属性创建一个 Habit 实例
  const Habit({
    required this.id,
    required this.name,
    required this.category,
    this.streak = 0,
    this.isCompleted = false,
    this.lastCompletedDate,
    this.goalType = 'none',
    this.goalValue,
    this.goalUnit,
    this.reminderEnabled = false,
    this.reminderTime,
    this.createdAt,
  });

  /// Create a copy with updated fields
  /// 创建一个更新了指定字段的副本
  Habit copyWith({
    String? id,
    String? name,
    HabitCategory? category,
    int? streak,
    bool? isCompleted,
    DateTime? lastCompletedDate,
    String? goalType,
    int? goalValue,
    String? goalUnit,
    bool clearGoal = false,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    bool clearLastCompletedDate = false,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      streak: streak ?? this.streak,
      isCompleted: isCompleted ?? this.isCompleted,
      lastCompletedDate: clearLastCompletedDate
          ? null
          : (lastCompletedDate ?? this.lastCompletedDate),
      goalType: goalType ?? this.goalType,
      goalValue: clearGoal ? null : (goalValue ?? this.goalValue),
      goalUnit: clearGoal ? null : (goalUnit ?? this.goalUnit),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Toggle completion status
  /// Note: lastCompletedDate is preserved on undo to maintain history context.
  /// The actual completion history is managed by FirestoreService.
  /// 切换完成状态
  /// 注意：撤销时保留 lastCompletedDate 以维持历史上下文。
  /// 实际完成历史由 FirestoreService 管理。
  @Deprecated('Use FirestoreService.toggleHabitCompletion() instead - this method has incorrect streak logic')
  Habit toggleCompletion() {
    return copyWith(
      isCompleted: !isCompleted,
      streak: !isCompleted ? streak + 1 : (streak > 0 ? streak - 1 : 0),
      lastCompletedDate: !isCompleted ? DateTime.now() : lastCompletedDate,
    );
  }

  /// Equality operator comparing all fields
  /// 比较所有字段的相等运算符
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habit &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.streak == streak &&
        other.isCompleted == isCompleted &&
        other.lastCompletedDate == lastCompletedDate &&
        other.goalType == goalType &&
        other.goalValue == goalValue &&
        other.goalUnit == goalUnit &&
        other.reminderEnabled == reminderEnabled &&
        other.reminderTime == reminderTime &&
        other.createdAt == createdAt;
  }

  /// Hash code combining all fields
  /// 组合所有字段的哈希码
  @override
  int get hashCode => Object.hash(
        id,
        name,
        category,
        streak,
        isCompleted,
        lastCompletedDate,
        goalType,
        goalValue,
        goalUnit,
        reminderEnabled,
        reminderTime,
        createdAt,
      );

  /// String representation for debugging
  /// 用于调试的字符串表示
  @override
  String toString() {
    return 'Habit(id: $id, name: $name, category: $category, streak: $streak, isCompleted: $isCompleted, goal: $goalType $goalValue $goalUnit, reminder: $reminderEnabled at $reminderTime)';
  }
}
