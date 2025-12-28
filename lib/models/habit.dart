import 'package:flutter/material.dart';
import 'habit_category.dart';

/// Habit model representing a user's habit
class Habit {
  final String id;
  final String name;
  final HabitCategory category;
  final int streak;
  final bool isCompleted;
  final DateTime? lastCompletedDate;

  // Reminder settings
  final bool reminderEnabled;
  final TimeOfDay? reminderTime;

  const Habit({
    required this.id,
    required this.name,
    required this.category,
    this.streak = 0,
    this.isCompleted = false,
    this.lastCompletedDate,
    this.reminderEnabled = false,
    this.reminderTime,
  });

  /// Create a copy with updated fields
  Habit copyWith({
    String? id,
    String? name,
    HabitCategory? category,
    int? streak,
    bool? isCompleted,
    DateTime? lastCompletedDate,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      streak: streak ?? this.streak,
      isCompleted: isCompleted ?? this.isCompleted,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  /// Toggle completion status
  Habit toggleCompletion() {
    return copyWith(
      isCompleted: !isCompleted,
      streak: !isCompleted ? streak + 1 : streak,
      lastCompletedDate: !isCompleted ? DateTime.now() : lastCompletedDate,
    );
  }

  @override
  String toString() {
    return 'Habit(id: $id, name: $name, category: $category, streak: $streak, isCompleted: $isCompleted, reminder: $reminderEnabled at $reminderTime)';
  }
}
