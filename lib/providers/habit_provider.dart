import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/subscription_models.dart';
import '../services/firestore_service.dart';
import '../services/badge_service.dart';
import '../services/notification_service.dart';
import '../services/subscription_service.dart';
import 'dart:async';

/// Provider for managing habits data
class HabitProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final BadgeService _badgeService = BadgeService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<Habit> _habits = [];
  bool _isLoadingHabits = true;
  StreamSubscription<List<Habit>>? _habitsSubscription;

  // Track habits currently being toggled to prevent race conditions
  final Set<String> _togglingHabits = {};

  // Cached computed values (invalidated when _habits changes)
  int? _cachedBestStreak;

  HabitProvider() {
    _init();
  }

  void _init() {
    // BadgeService is initialized in main.dart, don't double-initialize
    _firestoreService.createUserIfNotExists();
    _habitsSubscription = _firestoreService.getHabits().listen((habits) {
      _habits = habits;
      _isLoadingHabits = false;
      _cachedBestStreak = null; // Invalidate cached value
      _updateBadge();
      notifyListeners();
    });
  }

  /// Update app icon badge with incomplete habits count
  void _updateBadge() {
    final incompleteCount = _habits.where((h) => !h.isCompleted).length;
    _badgeService.updateBadgeCount(incompleteCount);
  }

  /// Clear all user-specific data on logout to prevent cross-user leaks
  void clearUserData() {
    _habitsSubscription?.cancel();
    _habitsSubscription = null;
    _habits = [];
    _isLoadingHabits = true;
    _togglingHabits.clear();
    _cachedBestStreak = null;
    notifyListeners();
  }

  /// Re-subscribe to Firestore for the newly logged-in user
  void reinitialize() {
    _habitsSubscription?.cancel();
    _habitsSubscription = null;
    _habits = [];
    _isLoadingHabits = true;
    _cachedBestStreak = null;
    notifyListeners();
    _init();
  }

  @override
  void dispose() {
    _habitsSubscription?.cancel();
    _togglingHabits.clear();
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

  /// Get best streak across all habits (cached)
  int get bestStreak {
    if (_cachedBestStreak != null) return _cachedBestStreak!;
    _cachedBestStreak = _habits.isEmpty
        ? 0
        : _habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    return _cachedBestStreak!;
  }

  /// Toggle habit completion status
  /// Returns false if toggle was skipped due to an in-progress operation
  Future<bool> toggleHabitCompletion(String habitId) async {
    // Prevent race condition: skip if this habit is already being toggled
    if (_togglingHabits.contains(habitId)) {
      debugPrint('Toggle skipped for $habitId - operation in progress');
      return false;
    }

    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return false;

    // Mark as toggling to prevent concurrent operations
    _togglingHabits.add(habitId);
    final oldHabit = _habits[index];

    try {
      // Delegate streak calculation to FirestoreService (single source of truth)
      // Only do optimistic UI update for isCompleted state
      final isCompletedToday = _isCompletedToday(oldHabit.lastCompletedDate);
      final willBeCompleted = !isCompletedToday;

      // Simple optimistic update - just flip completion status
      // The actual streak will be synced from Firestore stream
      final newHabit = oldHabit.copyWith(
        isCompleted: willBeCompleted,
        lastCompletedDate: willBeCompleted ? DateTime.now() : null,
        clearLastCompletedDate: !willBeCompleted,
      );
      _habits[index] = newHabit;
      notifyListeners();

      await _firestoreService.toggleHabitCompletion(oldHabit);
      return true;
    } catch (e) {
      // Revert on failure
      _habits[index] = oldHabit;
      notifyListeners();
      debugPrint('Error toggling habit: $e');
      rethrow;
    } finally {
      // Always remove from toggling set
      _togglingHabits.remove(habitId);
    }
  }

  /// Check if habit was completed today
  bool _isCompletedToday(DateTime? lastCompletedDate) {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    final localDate = lastCompletedDate.toLocal();
    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }

  /// Check if user can add more habits based on subscription tier
  bool get canAddHabit => _subscriptionService.canAddHabit(_habits.length);

  /// Get remaining habits that can be added
  int get remainingHabitsAllowed =>
      _subscriptionService.getLimits(_habits.length).remainingHabits;

  /// Add new habit with subscription limit check
  /// Throws an exception if habit limit is reached
  Future<void> addHabit(Habit habit) async {
    // Check subscription limits before adding
    if (!_subscriptionService.canAddHabit(_habits.length)) {
      final tier = _subscriptionService.currentTier;
      throw HabitLimitExceededException(
        'You\'ve reached the ${tier.maxHabits} habit limit for the ${tier.displayName} plan. '
        'Upgrade to add more habits.',
      );
    }

    try {
      await _firestoreService.addHabit(habit);
    } catch (e) {
      debugPrint('Error adding habit: $e');
      rethrow;
    }
  }

  /// Update existing habit
  Future<void> updateHabit(Habit habit) async {
    try {
      await _firestoreService.updateHabit(habit);
    } catch (e) {
      debugPrint('Error updating habit: $e');
      rethrow;
    }
  }

  /// Remove habit
  Future<void> removeHabit(String habitId) async {
    try {
      await NotificationService().cancelHabitReminder(habitId);
      await _firestoreService.deleteHabit(habitId);
    } catch (e) {
      debugPrint('Error removing habit: $e');
      rethrow;
    }
  }
}

/// Exception thrown when user tries to add more habits than their tier allows
class HabitLimitExceededException implements Exception {
  final String message;
  HabitLimitExceededException(this.message);

  @override
  String toString() => message;
}
