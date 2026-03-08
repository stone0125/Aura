// =============================================================================
// progress_provider.dart — Progress Analytics Provider
// 进度分析 Provider
//
// Calculates all analytics data from habit completion history: completion rates,
// category breakdowns, weekly heatmaps, trend charts, top/bottom performers,
// and achievements. Depends on HabitProvider via ProxyProvider.
//
// 从习惯完成历史计算所有分析数据：完成率、类别细分、每周热力图、趋势图表、
// 最佳/最差表现者和成就。通过 ProxyProvider 依赖 HabitProvider。
// =============================================================================

import 'package:flutter/material.dart';
import '../models/progress_models.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../services/firestore_service.dart';

/// Provider for managing progress and analytics data
class ProgressProvider with ChangeNotifier {
  DateRange _selectedRange = DateRange.thisWeek;
  ProgressStats? _stats;
  List<CategoryBreakdown> _categoryBreakdown = [];
  List<DayHeatmapData> _weeklyHeatmap = [];
  List<TrendDataPoint> _trendData = [];
  List<HabitPerformance> _topPerformers = [];
  List<HabitPerformance> _bottomPerformers = [];
  List<Achievement> _achievements = [];
  WeeklySummary? _weeklySummary;
  bool _isLoading = false;

  // Local cache of habits to calculate from
  List<Habit> _habits = [];

  // Cached achievement lists (invalidated when _achievements changes)
  List<Achievement>? _cachedUnlockedAchievements;
  List<Achievement>? _cachedLockedAchievements;

  // Getters
  DateRange get selectedRange => _selectedRange;
  ProgressStats? get stats => _stats;
  List<CategoryBreakdown> get categoryBreakdown => _categoryBreakdown;
  List<DayHeatmapData> get weeklyHeatmap => _weeklyHeatmap;
  List<TrendDataPoint> get trendData => _trendData;
  List<HabitPerformance> get topPerformers => _topPerformers;
  List<HabitPerformance> get bottomPerformers => _bottomPerformers;
  List<Achievement> get achievements => _achievements;
  WeeklySummary? get weeklySummary => _weeklySummary;
  bool get isLoading => _isLoading;

  // Cached achievement getters - computed once per data change
  List<Achievement> get unlockedAchievements {
    _cachedUnlockedAchievements ??= _achievements.where((a) => a.isUnlocked).toList();
    return _cachedUnlockedAchievements!;
  }

  List<Achievement> get lockedAchievements {
    _cachedLockedAchievements ??= _achievements.where((a) => !a.isUnlocked).toList();
    return _cachedLockedAchievements!;
  }

  /// Invalidate cached achievement lists when achievements change
  void _invalidateAchievementCache() {
    _cachedUnlockedAchievements = null;
    _cachedLockedAchievements = null;
  }

  /// Called by ProxyProvider when habits change
  void updateHabits(List<Habit> habits) {
    _habits = habits;
    _calculateAllStats();
  }

  /// Change selected date range
  void setDateRange(DateRange range) {
    _selectedRange = range;
    _calculateAllStats(); // already calls notifyListeners()
  }

  void _calculateAllStats() {
    if (_habits.isEmpty) {
      _stats = const ProgressStats(
        completionRate: 0,
        daysTracked: 0,
        bestStreak: 0,
        totalHabits: 0,
        completedToday: 0,
        totalToday: 0,
      );
      _categoryBreakdown = [];
      _weeklyHeatmap = [];
      _trendData = [];
      _topPerformers = [];
      _bottomPerformers = [];
      notifyListeners();
      return;
    }

    _calculateStats();
    _calculateCategoryBreakdown();
    _calculateWeeklyHeatmap();
    _calculateTrendData();
    _calculatePerformers();
    _calculateAchievements(); // This would be more complex in real app, keeping simple for now
    // _generateWeeklySummary(); // Keep this optional or simplified

    notifyListeners();
  }

  void _calculateStats() {
    final totalHabits = _habits.length;
    final completedToday = _habits.where((h) => h.isCompleted).length;

    // Calculate historical completion rate based on selected range
    double completionRate = 0.0;
    if (totalHabits > 0 && _habitHistories.isNotEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final rangeStart = _getRangeStartDate();
      final startDay = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);

      int totalPossible = 0;
      int totalCompleted = 0;

      // Loop forward from range start to today (inclusive)
      for (var date = startDay; !date.isAfter(today); date = date.add(const Duration(days: 1))) {
        final dateKey = _dateToKey(date);

        for (var h in _habits) {
          // Only count this habit if it existed on this date
          if (!_habitExistedOnDate(h, date)) continue;
          totalPossible++;

          final normalizedDates = _normalizedHistories[h.id];
          if (normalizedDates != null && normalizedDates.contains(dateKey)) {
            totalCompleted++;
          }
        }
      }

      completionRate = totalPossible > 0 ? totalCompleted / totalPossible : 0.0;
    } else {
      // Fallback to today's rate if no history
      completionRate = totalHabits > 0 ? completedToday / totalHabits : 0.0;
    }

    // Best streak across all habits
    int bestStreak = 0;
    if (_habits.isNotEmpty) {
      bestStreak = _habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    }

    // Calculate days tracked from earliest completion in history
    int daysTracked = 0;
    DateTime? earliestDate;
    for (var history in _habitHistories.values) {
      for (var date in history) {
        if (earliestDate == null || date.isBefore(earliestDate)) {
          earliestDate = date;
        }
      }
    }
    if (earliestDate != null) {
      daysTracked = DateTime.now().difference(earliestDate).inDays + 1;
    }

    _stats = ProgressStats(
      completionRate: completionRate,
      daysTracked: daysTracked > 0 ? daysTracked : 1,
      bestStreak: bestStreak,
      totalHabits: totalHabits,
      completedToday: completedToday,
      totalToday: totalHabits,
    );
  }

  void _calculateCategoryBreakdown() {
    Map<HabitCategory, int> counts = {};
    for (var h in _habits) {
      counts[h.category] = (counts[h.category] ?? 0) + 1;
    }

    int total = _habits.length;
    _categoryBreakdown = counts.entries.map((e) {
      return CategoryBreakdown(
        category: e.key,
        habitCount: e.value,
        percentage: total > 0 ? e.value / total : 0,
      );
    }).toList();
  }

  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, List<DateTime>> _habitHistories = {};

  // Normalized date cache for O(1) lookups - keys are "YYYY-MM-DD" format
  Map<String, Set<String>> _normalizedHistories = {};

  /// Build normalized date cache from habit histories for O(1) date lookups
  void _buildNormalizedHistories() {
    _normalizedHistories = _habitHistories.map((id, dates) => MapEntry(
      id,
      dates.map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}').toSet(),
    ));
  }

  /// Convert DateTime to normalized string key
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Find the earliest date across all histories and habit createdAt dates.
  DateTime _getEarliestDate() {
    DateTime? earliest;
    for (var history in _habitHistories.values) {
      for (var date in history) {
        if (earliest == null || date.isBefore(earliest)) {
          earliest = date;
        }
      }
    }
    for (var h in _habits) {
      if (h.createdAt != null && (earliest == null || h.createdAt!.isBefore(earliest))) {
        earliest = h.createdAt;
      }
    }
    // Fallback to 7 days ago if no data at all
    return earliest ?? DateTime.now().subtract(const Duration(days: 6));
  }

  /// Get the start date for the currently selected range.
  /// For week/month returns the calendar boundary; for allTime uses earliest date.
  DateTime _getRangeStartDate() {
    return _selectedRange.startDate ?? _getEarliestDate();
  }

  /// Check if a habit existed on a given date (createdAt is null or <= date).
  bool _habitExistedOnDate(Habit habit, DateTime date) {
    if (habit.createdAt == null) return true; // legacy habit, assume always existed
    final createdDay = DateTime(habit.createdAt!.year, habit.createdAt!.month, habit.createdAt!.day);
    return !createdDay.isAfter(date);
  }

  /// Check if a specific habit was completed on a specific date - O(1) lookup
  bool wasHabitCompletedOnDate(String habitId, DateTime date) {
    final normalizedDates = _normalizedHistories[habitId];
    if (normalizedDates == null) return false;
    return normalizedDates.contains(_dateToKey(date));
  }

  /// Initialize progress data
  Future<void> initialize() async {
    _isLoading = true;
    // notifyListeners(); // Delay notification or rely on initial state if desirable, but typically yes.
    // However, if called from initState, avoid notifyListeners immediately if possible or use future.delayed zero.
    // Safe explicitly here:
    await _fetchAllHistory();
    _recalculateAll();
    _isLoading = false;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _fetchAllHistory();
    _recalculateAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchAllHistory() async {
    if (_habits.isEmpty) return;
    try {
      // Prune old habit histories for habits that no longer exist
      _pruneOldHistories();

      // Fetch history for current habits (limited to 90 days)
      // Use individual try-catch to prevent one failure from stopping all fetches
      final futures = _habits.map((h) async {
        try {
          final history = await _firestoreService.getHabitHistory(h.id);
          _habitHistories[h.id] = history;
        } catch (e) {
          debugPrint("Error fetching history for habit ${h.id}: $e");
          // Keep existing history or set empty list on failure
          _habitHistories[h.id] ??= [];
        }
      }).toList();

      await Future.wait(futures, eagerError: false);

      // Build normalized cache for O(1) lookups
      _buildNormalizedHistories();
    } catch (e) {
      debugPrint("Error in _fetchAllHistory: $e");
    }
  }

  /// Remove history entries for habits that no longer exist
  /// This prevents unbounded memory growth
  void _pruneOldHistories() {
    final currentHabitIds = _habits.map((h) => h.id).toSet();
    _habitHistories.removeWhere((id, _) => !currentHabitIds.contains(id));
    _normalizedHistories.removeWhere((id, _) => !currentHabitIds.contains(id));
  }

  void _recalculateAll() {
    _calculateAllStats();
    // notifyListeners() already called in _calculateAllStats
  }

  // Updated Heatmap Calculation using Real History - O(1) lookups
  void _calculateWeeklyHeatmap() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    _weeklyHeatmap = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final dateKey = _dateToKey(date);

      int completed = 0;
      int total = 0;

      for (var h in _habits) {
        // Only count habits that existed on this date
        if (!_habitExistedOnDate(h, date)) continue;
        total++;

        final normalizedDates = _normalizedHistories[h.id];
        if (normalizedDates != null && normalizedDates.contains(dateKey)) {
          completed++;
        }
      }

      return DayHeatmapData(
        date: date,
        completed: completed,
        total: total,
        completionRate: total > 0 ? completed / total : 0,
      );
    });
  }

  // Updated Trend Data using Real History - O(1) lookups
  void _calculateTrendData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = _getRangeStartDate();
    final startDay = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);

    _trendData = [];
    for (var date = startDay; !date.isAfter(today); date = date.add(const Duration(days: 1))) {
      final dateKey = _dateToKey(date);

      int completed = 0;
      int total = 0;

      for (var h in _habits) {
        if (!_habitExistedOnDate(h, date)) continue;
        total++;

        final normalizedDates = _normalizedHistories[h.id];
        if (normalizedDates != null && normalizedDates.contains(dateKey)) {
          completed++;
        }
      }

      _trendData.add(TrendDataPoint(
        date: date,
        completionRate: total > 0 ? completed / total : 0.0,
      ));
    }
  }

  void _calculatePerformers() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = _getRangeStartDate();
    final startDay = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);

    // Build performance data for each habit
    List<_HabitPerfData> perfData = [];

    for (var h in _habits) {
      // Per-habit: effective start is the later of range start or habit creation
      DateTime effectiveStart = startDay;
      if (h.createdAt != null) {
        final createdDay = DateTime(h.createdAt!.year, h.createdAt!.month, h.createdAt!.day);
        if (createdDay.isAfter(effectiveStart)) {
          effectiveStart = createdDay;
        }
      }

      final habitRangeDays = today.difference(effectiveStart).inDays + 1;
      if (habitRangeDays <= 0) continue; // habit created after today (shouldn't happen)

      final history = _habitHistories[h.id] ?? [];
      // Count completions within the effective range
      final completionsInRange = history
          .where((d) {
            final day = DateTime(d.year, d.month, d.day);
            return !day.isBefore(effectiveStart) && !day.isAfter(today);
          })
          .length;

      final successRate = habitRangeDays > 0 ? completionsInRange / habitRangeDays : 0.0;
      perfData.add(
        _HabitPerfData(
          habit: h,
          completions: completionsInRange,
          totalDays: habitRangeDays,
          successRate: successRate.clamp(0.0, 1.0),
        ),
      );
    }

    // Sort once by success rate descending
    perfData.sort((a, b) => b.successRate.compareTo(a.successRate));

    // Guard against empty perfData
    if (perfData.isEmpty) {
      _topPerformers = [];
      _bottomPerformers = [];
      return;
    }

    // Top performers - first 3 (highest success rates)
    // Use math.min to avoid taking more than available
    final topCount = perfData.length < 3 ? perfData.length : 3;
    _topPerformers = perfData
        .take(topCount)
        .map(
          (p) => HabitPerformance(
            habit: p.habit,
            successRate: p.successRate,
            completions: p.completions,
            totalDays: p.totalDays,
          ),
        )
        .toList();

    // Bottom performers - last 3 (lowest success rates)
    // For small lists (3 or fewer habits), bottom performers overlap with top
    // Take from the end of the sorted list (lowest rates)
    final bottomCount = perfData.length < 3 ? perfData.length : 3;
    _bottomPerformers = perfData
        .skip(perfData.length - bottomCount)
        .map(
          (p) => HabitPerformance(
            habit: p.habit,
            successRate: p.successRate,
            completions: p.completions,
            totalDays: p.totalDays,
          ),
        )
        .toList();
  }

  void _calculateAchievements() {
    // Invalidate cached lists since achievements are being recalculated
    _invalidateAchievementCache();
    final now = DateTime.now();
    final totalStreak = _stats?.bestStreak ?? 0;
    final totalCompletions = _habitHistories.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final totalHabits = _habits.length;
    final daysTracked = _stats?.daysTracked ?? 0;

    // Count category diversity
    final uniqueCategories = _habits.map((h) => h.category).toSet().length;

    _achievements = [
      // --- Getting Started ---
      Achievement(
        id: 'first_step',
        name: 'First Step',
        description: 'Complete your first habit',
        icon: Icons.directions_walk_rounded,
        category: AchievementCategory.completion,
        targetValue: 1,
        currentValue: totalCompletions,
        isUnlocked: totalCompletions >= 1,
        unlockedAt: totalCompletions >= 1 ? now : null,
      ),
      Achievement(
        id: 'getting_started',
        name: 'Getting Started',
        description: 'Create your first habit',
        icon: Icons.add_circle_rounded,
        category: AchievementCategory.category,
        targetValue: 1,
        currentValue: totalHabits,
        isUnlocked: totalHabits >= 1,
        unlockedAt: totalHabits >= 1 ? now : null,
      ),

      // --- Streak Milestones ---
      Achievement(
        id: 'week_warrior',
        name: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: Icons.local_fire_department_rounded,
        category: AchievementCategory.streak,
        targetValue: 7,
        currentValue: totalStreak,
        isUnlocked: totalStreak >= 7,
        unlockedAt: totalStreak >= 7 ? now : null,
      ),
      Achievement(
        id: 'two_week_triumph',
        name: 'Two Week Triumph',
        description: 'Maintain a 14-day streak',
        icon: Icons.whatshot_rounded,
        category: AchievementCategory.streak,
        targetValue: 14,
        currentValue: totalStreak,
        isUnlocked: totalStreak >= 14,
        unlockedAt: totalStreak >= 14 ? now : null,
      ),
      Achievement(
        id: 'three_week_champion',
        name: 'Three Week Champion',
        description: 'Maintain a 21-day streak',
        icon: Icons.military_tech_rounded,
        category: AchievementCategory.streak,
        targetValue: 21,
        currentValue: totalStreak,
        isUnlocked: totalStreak >= 21,
        unlockedAt: totalStreak >= 21 ? now : null,
      ),
      Achievement(
        id: 'streak_master',
        name: 'Streak Master',
        description: 'Maintain a 30-day streak',
        icon: Icons.star_rounded,
        category: AchievementCategory.streak,
        targetValue: 30,
        currentValue: totalStreak,
        isUnlocked: totalStreak >= 30,
        unlockedAt: totalStreak >= 30 ? now : null,
      ),
      Achievement(
        id: 'iron_will',
        name: 'Iron Will',
        description: 'Maintain a 60-day streak',
        icon: Icons.shield_rounded,
        category: AchievementCategory.streak,
        targetValue: 60,
        currentValue: totalStreak,
        isUnlocked: totalStreak >= 60,
        unlockedAt: totalStreak >= 60 ? now : null,
      ),
      Achievement(
        id: 'legend',
        name: 'Legend',
        description: 'Maintain a 90-day streak',
        icon: Icons.diamond_rounded,
        category: AchievementCategory.streak,
        targetValue: 90,
        currentValue: totalStreak,
        isUnlocked: totalStreak >= 90,
        unlockedAt: totalStreak >= 90 ? now : null,
      ),

      // --- Habit Collection ---
      Achievement(
        id: 'habit_collector',
        name: 'Habit Collector',
        description: 'Track 5 different habits',
        icon: Icons.grid_view_rounded,
        category: AchievementCategory.category,
        targetValue: 5,
        currentValue: totalHabits,
        isUnlocked: totalHabits >= 5,
        unlockedAt: totalHabits >= 5 ? now : null,
      ),
      Achievement(
        id: 'habit_master',
        name: 'Habit Master',
        description: 'Track 10 different habits',
        icon: Icons.apps_rounded,
        category: AchievementCategory.category,
        targetValue: 10,
        currentValue: totalHabits,
        isUnlocked: totalHabits >= 10,
        unlockedAt: totalHabits >= 10 ? now : null,
      ),
      Achievement(
        id: 'well_rounded',
        name: 'Well Rounded',
        description: 'Track habits in 3+ categories',
        icon: Icons.pie_chart_rounded,
        category: AchievementCategory.category,
        targetValue: 3,
        currentValue: uniqueCategories,
        isUnlocked: uniqueCategories >= 3,
        unlockedAt: uniqueCategories >= 3 ? now : null,
      ),

      // --- Completion Milestones ---
      Achievement(
        id: 'century_club',
        name: 'Century Club',
        description: 'Complete 100 total check-ins',
        icon: Icons.emoji_events_rounded,
        category: AchievementCategory.completion,
        targetValue: 100,
        currentValue: totalCompletions,
        isUnlocked: totalCompletions >= 100,
        unlockedAt: totalCompletions >= 100 ? now : null,
      ),
      Achievement(
        id: 'five_hundred',
        name: 'High Five Hundred',
        description: 'Complete 500 total check-ins',
        icon: Icons.workspace_premium_rounded,
        category: AchievementCategory.completion,
        targetValue: 500,
        currentValue: totalCompletions,
        isUnlocked: totalCompletions >= 500,
        unlockedAt: totalCompletions >= 500 ? now : null,
      ),
      Achievement(
        id: 'thousand_club',
        name: 'Thousand Club',
        description: 'Complete 1000 total check-ins',
        icon: Icons.auto_awesome_rounded,
        category: AchievementCategory.completion,
        targetValue: 1000,
        currentValue: totalCompletions,
        isUnlocked: totalCompletions >= 1000,
        unlockedAt: totalCompletions >= 1000 ? now : null,
      ),

      // --- Consistency ---
      Achievement(
        id: 'month_master',
        name: 'Month Master',
        description: 'Track habits for 30 days',
        icon: Icons.calendar_month_rounded,
        category: AchievementCategory.consistency,
        targetValue: 30,
        currentValue: daysTracked,
        isUnlocked: daysTracked >= 30,
        unlockedAt: daysTracked >= 30 ? now : null,
      ),
    ];
  }

  /// Clear all user-specific data on logout
  void clearUserData() {
    _habits = [];
    _habitHistories.clear();
    _normalizedHistories = {};
    _stats = null;
    _categoryBreakdown = [];
    _weeklyHeatmap = [];
    _trendData = [];
    _topPerformers = [];
    _bottomPerformers = [];
    _achievements = [];
    _weeklySummary = null;
    _isLoading = false;
    _cachedUnlockedAchievements = null;
    _cachedLockedAchievements = null;
    notifyListeners();
  }

  /// Calculate trend percentage change
  double getTrendChange() {
    if (_trendData.length < 2) return 0.0;

    final halfPoint = _trendData.length ~/ 2;

    // Guard: ensure we have enough data points
    if (halfPoint <= 0 || _trendData.length <= halfPoint) return 0.0;

    // Calculate first half average with empty list guard
    final firstHalfData = _trendData.take(halfPoint).map((d) => d.completionRate).toList();
    if (firstHalfData.isEmpty) return 0.0;
    final firstHalfAvg = firstHalfData.reduce((a, b) => a + b) / firstHalfData.length;

    // Calculate second half average with empty list guard
    final secondHalfData = _trendData.skip(halfPoint).map((d) => d.completionRate).toList();
    if (secondHalfData.isEmpty) return 0.0;
    final secondHalfAvg = secondHalfData.reduce((a, b) => a + b) / secondHalfData.length;

    // Guard against division by zero
    if (firstHalfAvg == 0) return secondHalfAvg > 0 ? 100.0 : 0.0;
    return ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100;
  }
}

/// Helper class for calculating habit performance
class _HabitPerfData {
  final Habit habit;
  final int completions;
  final int totalDays;
  final double successRate;

  _HabitPerfData({
    required this.habit,
    required this.completions,
    required this.totalDays,
    required this.successRate,
  });
}
