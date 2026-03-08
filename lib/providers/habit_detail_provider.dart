// =============================================================================
// habit_detail_provider.dart — Habit Detail Provider
// 习惯详情 Provider
//
// Manages detailed data for a single habit: completion history, calendar data,
// statistics (streaks, completion rate, best day), chart data, and AI-generated
// insights. Loads history from Firestore and AI insights from Cloud Functions.
//
// 管理单个习惯的详细数据：完成历史、日历数据、统计信息（连续记录、完成率、
// 最佳日期）、图表数据和 AI 生成的洞察。从 Firestore 加载历史，
// 从 Cloud Functions 加载 AI 洞察。
// =============================================================================

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/habit.dart';
import '../models/habit_stats.dart';
import '../services/firestore_service.dart';
import '../services/subscription_service.dart';

/// Provider for managing habit detail data
class HabitDetailProvider with ChangeNotifier {
  Habit? _habit;
  HabitStats? _stats;
  List<HabitCompletion> _completions = [];
  AIInsight? _aiInsight;
  bool _isLoadingInsight = false;
  bool _isLoadingData = false;
  String? _errorMessage;
  Map<DateTime, bool> _calendarData = {};

  // Cached computed value (invalidated when _completions changes)
  bool? _cachedIsCompletedToday;
  bool _isToggling = false;
  bool _isDisposed = false;

  // Getters
  Habit? get habit => _habit;
  HabitStats? get stats => _stats;
  List<HabitCompletion> get completions => _completions;
  AIInsight? get aiInsight => _aiInsight;
  bool get isLoadingInsight => _isLoadingInsight;
  bool get isLoadingData => _isLoadingData;
  String? get errorMessage => _errorMessage;
  Map<DateTime, bool> get calendarData => _calendarData;

  /// Check if habit was completed today (cached)
  bool get isCompletedToday {
    _cachedIsCompletedToday ??= _completions.any((c) => c.isToday);
    return _cachedIsCompletedToday!;
  }

  final FirestoreService _firestoreService = FirestoreService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  void _safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Load habit details with real history
  Future<void> loadHabitDetails(Habit habit) async {
    _habit = habit;
    _errorMessage = null;
    _isLoadingData = true;
    _cachedIsCompletedToday = null; // Invalidate cache
    _aiInsight = null; // Clear previous habit's insight
    _isLoadingInsight = false; // Reset loading flag
    _safeNotifyListeners();

    await _loadData();

    // Fire-and-forget AI insight load (it manages its own loading state)
    if (_aiInsight?.isStale ?? true) {
      _loadAIInsight(); // No await — don't block UI for up to 30s
    }
  }

  /// Load real data from Firestore
  Future<void> _loadData() async {
    if (_habit == null) return;

    _isLoadingData = true;
    _errorMessage = null;
    _cachedIsCompletedToday = null; // Invalidate cache before reload
    // Note: notifyListeners not called here to avoid double notification

    try {
      final history = await _firestoreService.getHabitHistory(_habit!.id);

      // Convert to completions list
      _completions = history
          .map(
            (date) => HabitCompletion(
              id: date.millisecondsSinceEpoch.toString(),
              date: date,
              time: '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
              method: CompletionMethod.manual, // Default
              notes: '',
            ),
          )
          .toList();

      // Sort completions (newest first)
      _completions.sort((a, b) => b.date.compareTo(a.date));

      // Build Calendar Data
      _calendarData = {};
      for (var date in history) {
        _calendarData[DateTime(date.year, date.month, date.day)] = true;
      }

      // Calculate Stats
      _calculateStats(history);
    } catch (e) {
      debugPrint("Error loading habit details: $e");
      _errorMessage = 'Failed to load habit data. Please try again.';
    } finally {
      _isLoadingData = false;
      _safeNotifyListeners();
    }
  }

  void _calculateStats(List<DateTime> history) {
    if (_habit == null) return;

    // Calculate streaks
    int currentStreak = 0;
    int longestStreak = 0;

    // Sort dates ascending for streak calc
    var sortedDates = List<DateTime>.from(history);
    sortedDates.sort((a, b) => a.compareTo(b));

    // Normalize to YMD to avoid time issues
    var uniqueDates = sortedDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList();
    uniqueDates.sort((a, b) => a.compareTo(b));

    if (uniqueDates.isNotEmpty) {
      // Convert to Set for O(1) lookups in while loop (was O(n) per iteration)
      final uniqueDateSet = uniqueDates.toSet();

      // Current Streak Calculation
      // Streak is valid if:
      // 1. Today is completed, OR
      // 2. Yesterday is completed (user still has today to maintain streak)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      if (uniqueDateSet.contains(today)) {
        // Today completed - count backwards from today
        currentStreak = 1;
        var checkDate = yesterday;
        while (uniqueDateSet.contains(checkDate)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      } else if (uniqueDateSet.contains(yesterday)) {
        // Yesterday completed but not today - streak still valid
        // User hasn't broken the streak yet (they have until end of today)
        currentStreak = 1;
        var checkDate = yesterday.subtract(const Duration(days: 1));
        while (uniqueDateSet.contains(checkDate)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      } else {
        // Neither today nor yesterday - streak is broken
        currentStreak = 0;
      }

      // Longest Streak
      int tempStreak = 0;
      DateTime? lastDate;
      for (var date in uniqueDates) {
        if (lastDate == null) {
          tempStreak = 1;
        } else {
          if (date.difference(lastDate).inDays == 1) {
            tempStreak++;
          } else {
            if (tempStreak > longestStreak) longestStreak = tempStreak;
            tempStreak = 1;
          }
        }
        lastDate = date;
      }
      if (tempStreak > longestStreak) longestStreak = tempStreak;
    }

    // Calculate days tracked (from first completion to now)
    int daysTracked = 1;
    if (uniqueDates.isNotEmpty) {
      final firstDate = uniqueDates.first;
      final now = DateTime.now();
      daysTracked = now.difference(firstDate).inDays + 1;
    }

    // Calculate actual completion rate
    final double completionRate = daysTracked > 0
        ? (history.length / daysTracked * 100).clamp(0.0, 100.0)
        : 0.0;

    // Calculate best day of week
    final dayCount = <int, int>{};
    for (var date in uniqueDates) {
      dayCount[date.weekday] = (dayCount[date.weekday] ?? 0) + 1;
    }
    String bestDay = 'No data';
    if (dayCount.isNotEmpty) {
      final bestDayNum = dayCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      if (bestDayNum >= 1 && bestDayNum <= 7) {
        bestDay = dayNames[bestDayNum - 1];
      }
    }

    _stats = HabitStats(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalCompletions: history.length,
      completionRate: completionRate,
      bestDay: bestDay,
      bestTime: 'Morning', // Would need time data to calculate
    );

    // Update local habit object to reflect current stats
    // This ensures that toggle actions use the correct current state
    // CRITICAL: must also update lastCompletedDate so toggleHabitCompletion
    // correctly detects today's completion state via _isCompletedToday()
    if (_habit != null) {
      _habit = _habit!.copyWith(
        streak: currentStreak,
        isCompleted: isCompletedToday,
        lastCompletedDate: isCompletedToday ? DateTime.now() : null,
        clearLastCompletedDate: !isCompletedToday,
      );
    }
  }

  /// Load AI insight from Cloud Function
  Future<void> _loadAIInsight() async {
    if (_habit == null) return;

    // Check monthly AI report limit
    if (!_subscriptionService.canUseAIReport()) {
      _aiInsight = AIInsight(
        text: 'Monthly AI report limit reached. Upgrade for more insights.',
        confidence: 'low',
        generatedAt: DateTime.now(),
        supportingIcon: 'lock',
      );
      _safeNotifyListeners();
      return;
    }

    _isLoadingInsight = true;
    _safeNotifyListeners();

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable(
        'generateHabitInsight',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      // Calculate recent completions (last 7 days)
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final recentCompletions = _completions
          .where((c) => c.date.isAfter(weekAgo))
          .length;

      final result = await callable.call({
        'habitName': _habit!.name,
        'category': _habit!.category.name,
        'currentStreak': _stats?.currentStreak ?? _habit!.streak,
        'totalCompletions': _stats?.totalCompletions ?? _completions.length,
        'recentDays': recentCompletions,
      });

      // Validate response data
      final data = result.data;
      if (data == null || data is! Map) {
        throw const FormatException('Invalid insight response format');
      }
      final map = Map<String, dynamic>.from(data);
      _aiInsight = AIInsight(
        text: map['text']?.toString() ?? 'Keep going!',
        confidence: map['confidence']?.toString() ?? 'medium',
        generatedAt: DateTime.now(),
        supportingIcon: map['icon']?.toString() ?? 'trending_up',
      );

      // Record usage after successful API call
      await _subscriptionService.recordAIReportUsage();
    } catch (e) {
      debugPrint('Error loading AI insight: $e');
      // Fallback to simple message
      _aiInsight = AIInsight(
        text: 'Keep building your habit!',
        confidence: 'low',
        generatedAt: DateTime.now(),
        supportingIcon: 'psychology',
      );
    } finally {
      _isLoadingInsight = false;
      _safeNotifyListeners();
    }
  }

  /// Refresh AI insight
  Future<void> refreshAIInsight() async {
    await _loadAIInsight();
  }

  /// Mark habit as complete for today
  Future<void> completeHabit() async {
    if (_habit == null || _isToggling) return;

    _isToggling = true;
    try {
      await _firestoreService.toggleHabitCompletion(
        _habit!,
      ); // This handles history logging we added
      await _loadData(); // Reload to update UI
    } finally {
      _isToggling = false;
      _safeNotifyListeners();
    }
  }

  /// Undo today's completion (handled by toggle logic mostly, but explicit undo might be needed)
  Future<void> undoCompletion() async {
    await completeHabit(); // Toggle acts as undo if already completed
  }

  /// Get chart data for time range
  List<ChartDataPoint> getChartData(TimeRange timeRange) {
    final now = DateTime.now();
    final days = timeRange.days ?? 30; // Default to 30 if all time
    final points = <ChartDataPoint>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      final isCompleted = _calendarData[dateKey] ?? false;

      points.add(
        ChartDataPoint(
          date: dateKey,
          value: isCompleted ? 1.0 : 0.0,
          isCompleted: isCompleted,
        ),
      );
    }

    return points;
  }

  /// Clear all user-specific data on logout
  void clearUserData() {
    _habit = null;
    _stats = null;
    _completions = [];
    _aiInsight = null;
    _isLoadingInsight = false;
    _isLoadingData = false;
    _errorMessage = null;
    _calendarData = {};
    _cachedIsCompletedToday = null;
    _isToggling = false;
    _safeNotifyListeners();
  }

  /// Check if completion exists for a specific date
  bool isCompletedOn(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _calendarData[dateKey] ?? false;
  }
}
