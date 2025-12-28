import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/firestore_service.dart';
import '../services/badge_service.dart';
import 'dart:async';

/// Provider for managing habits data
class HabitProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final BadgeService _badgeService = BadgeService();
  List<Habit> _habits = [];
  bool _isLoadingHabits = true;
  StreamSubscription<List<Habit>>? _habitsSubscription;

  HabitProvider() {
    _init();
  }

  void _init() {
    _badgeService.initialize();
    _firestoreService.createUserIfNotExists();
    _habitsSubscription = _firestoreService.getHabits().listen((habits) {
      _habits = habits;
      _isLoadingHabits = false;
      _updateBadge();
      notifyListeners();
    });
  }

  /// Update app icon badge with incomplete habits count
  void _updateBadge() {
    final incompleteCount = _habits.where((h) => !h.isCompleted).length;
    _badgeService.updateBadgeCount(incompleteCount);
  }

  @override
  void dispose() {
    _habitsSubscription?.cancel();
    super.dispose();
  }

  // Getters
  List<Habit> get habits => _habits;
  List<Habit> get todaysHabits => _habits;
  bool get isLoadingHabits => _isLoadingHabits;

  /// Get completed habits count for today
  int get completedCount => _habits.where((h) => h.isCompleted).length;

  /// Get total habits count
  int get totalCount => _habits.length;

  /// Get completion rate (0.0 to 1.0)
  double get completionRate =>
      totalCount > 0 ? completedCount / totalCount : 0.0;

  /// Get best streak across all habits
  int get bestStreak => _habits.isEmpty
      ? 0
      : _habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

  /// Toggle habit completion status
  Future<void> toggleHabitCompletion(String habitId) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      // Optimistic update
      final oldHabit = _habits[index];
      final newHabit = oldHabit.toggleCompletion();
      _habits[index] = newHabit;
      notifyListeners();

      try {
        await _firestoreService.toggleHabitCompletion(oldHabit);
      } catch (e) {
        // Revert on failure
        _habits[index] = oldHabit;
        notifyListeners();
        debugPrint('Error toggling habit: $e');
      }
    }
  }

  /// Add new habit
  Future<void> addHabit(Habit habit) async {
    try {
      await _firestoreService.addHabit(habit);
    } catch (e) {
      debugPrint('Error adding habit: $e');
      rethrow;
    }
  }

  /// Remove habit
  Future<void> removeHabit(String habitId) async {
    try {
      await _firestoreService.deleteHabit(habitId);
    } catch (e) {
      debugPrint('Error removing habit: $e');
      rethrow;
    }
  }
}
