// =============================================================================
// habit_provider.dart — Habit State Management (Business Logic)
// 习惯状态管理（业务逻辑）
//
// Manages the habit list, real-time Firestore synchronization, streak tracking,
// and subscription limit checks. Uses ChangeNotifier pattern to notify UI of
// state changes. Key functions: toggleHabitCompletion(), addHabit(), removeHabit().
//
// 管理习惯列表、实时 Firestore 同步、连续记录追踪和订阅限制检查。
// 使用 ChangeNotifier 模式通知 UI 状态变化。
// 关键函数：toggleHabitCompletion()、addHabit()、removeHabit()。
// =============================================================================

import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/subscription_models.dart';
import '../services/firestore_service.dart';
import '../services/badge_service.dart';
import '../services/notification_service.dart';
import '../services/subscription_service.dart';
import 'dart:async';

/// Provider for managing habits data
/// 管理习惯数据的 Provider
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

  /// Constructor that initializes Firestore subscription
  /// 构造函数，初始化 Firestore 订阅
  HabitProvider() {
    _init();
  }

  /// Initialize Firestore user and start listening to habits stream
  /// 初始化 Firestore 用户并开始监听习惯数据流
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
  /// 用未完成习惯数更新应用图标徽章
  void _updateBadge() {
    final incompleteCount = _habits.where((h) => !h.isCompleted).length;
    _badgeService.updateBadgeCount(incompleteCount);
  }

  /// Clear all user-specific data on logout to prevent cross-user leaks
  /// 登出时清除所有用户数据，防止跨用户数据泄漏
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
  /// 为新登录的用户重新订阅 Firestore
  void reinitialize() {
    _habitsSubscription?.cancel();
    _habitsSubscription = null;
    _habits = [];
    _isLoadingHabits = true;
    _cachedBestStreak = null;
    notifyListeners();
    _init();
  }

  /// Dispose resources and cancel Firestore subscription
  /// 释放资源并取消 Firestore 订阅
  @override
  void dispose() {
    _habitsSubscription?.cancel();
    _togglingHabits.clear();
    super.dispose();
  }

  /// Get the list of all habits
  /// 获取所有习惯列表
  List<Habit> get habits => _habits;

  /// Get today's habits (currently returns all habits)
  /// 获取今日习惯（目前返回所有习惯）
  List<Habit> get todaysHabits => _habits;

  /// Whether habits are still loading from Firestore
  /// 习惯数据是否仍在从 Firestore 加载中
  bool get isLoadingHabits => _isLoadingHabits;

  /// Get completed habits count for today
  /// 获取今日已完成习惯数量
  int get completedCount => _habits.where((h) => h.isCompleted).length;

  /// Get total habits count
  /// 获取习惯总数
  int get totalCount => _habits.length;

  /// Get completion rate (0.0 to 1.0)
  /// 获取完成率（0.0 到 1.0）
  double get completionRate =>
      totalCount > 0 ? completedCount / totalCount : 0.0;

  /// Get best streak across all habits (cached)
  /// 获取所有习惯中的最佳连续记录（已缓存）
  int get bestStreak {
    if (_cachedBestStreak != null) return _cachedBestStreak!;
    _cachedBestStreak = _habits.isEmpty
        ? 0
        : _habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    return _cachedBestStreak!;
  }

  /// Toggle habit completion status
  /// Returns false if toggle was skipped due to an in-progress operation
  /// 切换习惯完成状态
  /// 如果因操作正在进行中而跳过切换，则返回 false
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
  /// 检查习惯今天是否已完成
  bool _isCompletedToday(DateTime? lastCompletedDate) {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    final localDate = lastCompletedDate.toLocal();
    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }

  /// Check if user can add more habits based on subscription tier
  /// 根据订阅等级检查用户是否可以添加更多习惯
  bool get canAddHabit => _subscriptionService.canAddHabit(_habits.length);

  /// Get remaining habits that can be added
  /// 获取还可以添加的习惯数量
  int get remainingHabitsAllowed =>
      _subscriptionService.getLimits(_habits.length).remainingHabits;

  /// Add new habit with subscription limit check
  /// Throws an exception if habit limit is reached
  /// 添加新习惯并检查订阅限制
  /// 如果达到习惯数量上限则抛出异常
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
  /// 更新现有习惯
  Future<void> updateHabit(Habit habit) async {
    try {
      await _firestoreService.updateHabit(habit);
    } catch (e) {
      debugPrint('Error updating habit: $e');
      rethrow;
    }
  }

  /// Remove habit
  /// 删除习惯
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
/// 当用户尝试添加超出其订阅等级允许数量的习惯时抛出的异常
class HabitLimitExceededException implements Exception {
  final String message;

  /// Create a habit limit exceeded exception with a message
  /// 创建一个带有消息的习惯数量超限异常
  HabitLimitExceededException(this.message);

  /// Return the exception message as string
  /// 将异常消息作为字符串返回
  @override
  String toString() => message;
}
