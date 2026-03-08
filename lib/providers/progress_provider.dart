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
/// 管理进度和分析数据的 Provider
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

  /// Get the currently selected date range
  /// 获取当前选中的日期范围
  DateRange get selectedRange => _selectedRange;

  /// Get the progress statistics
  /// 获取进度统计数据
  ProgressStats? get stats => _stats;

  /// Get the category breakdown list
  /// 获取类别细分列表
  List<CategoryBreakdown> get categoryBreakdown => _categoryBreakdown;

  /// Get the weekly heatmap data
  /// 获取每周热力图数据
  List<DayHeatmapData> get weeklyHeatmap => _weeklyHeatmap;

  /// Get the trend data points
  /// 获取趋势数据点
  List<TrendDataPoint> get trendData => _trendData;

  /// Get the top performing habits
  /// 获取表现最佳的习惯
  List<HabitPerformance> get topPerformers => _topPerformers;

  /// Get the bottom performing habits
  /// 获取表现最差的习惯
  List<HabitPerformance> get bottomPerformers => _bottomPerformers;

  /// Get the achievements list
  /// 获取成就列表
  List<Achievement> get achievements => _achievements;

  /// Get the weekly summary
  /// 获取每周总结
  WeeklySummary? get weeklySummary => _weeklySummary;

  /// Whether data is currently loading
  /// 数据是否正在加载中
  bool get isLoading => _isLoading;

  /// Get unlocked achievements (cached, computed once per data change)
  /// 获取已解锁的成就（已缓存，每次数据变化时计算一次）
  List<Achievement> get unlockedAchievements {
    _cachedUnlockedAchievements ??= _achievements.where((a) => a.isUnlocked).toList();
    return _cachedUnlockedAchievements!;
  }

  /// Get locked achievements (cached, computed once per data change)
  /// 获取未解锁的成就（已缓存，每次数据变化时计算一次）
  List<Achievement> get lockedAchievements {
    _cachedLockedAchievements ??= _achievements.where((a) => !a.isUnlocked).toList();
    return _cachedLockedAchievements!;
  }

  /// Invalidate cached achievement lists when achievements change
  /// 当成就数据变化时使缓存的成就列表失效
  void _invalidateAchievementCache() {
    _cachedUnlockedAchievements = null;
    _cachedLockedAchievements = null;
  }

  /// Called by ProxyProvider when habits change
  /// 当习惯数据变化时由 ProxyProvider 调用
  void updateHabits(List<Habit> habits) {
    _habits = habits;
    _calculateAllStats();
  }

  /// Change selected date range
  /// 更改选中的日期范围
  void setDateRange(DateRange range) {
    _selectedRange = range;
    _calculateAllStats(); // already calls notifyListeners()
  }

  /// Calculate all statistics from current habit data
  /// 从当前习惯数据计算所有统计信息
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

  /// Calculate core progress statistics (completion rate, streaks, days tracked)
  /// 计算核心进度统计数据（完成率、连续记录、追踪天数）
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

  /// Calculate category breakdown percentages
  /// 计算各类别的占比细分
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
  /// 从习惯历史构建规范化日期缓存，以实现 O(1) 的日期查找
  void _buildNormalizedHistories() {
    _normalizedHistories = _habitHistories.map((id, dates) => MapEntry(
      id,
      dates.map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}').toSet(),
    ));
  }

  /// Convert DateTime to normalized string key
  /// 将 DateTime 转换为规范化的字符串键
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Find the earliest date across all histories and habit createdAt dates
  /// 查找所有历史记录和习惯创建日期中最早的日期
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

  /// Get the start date for the currently selected range
  /// For week/month returns the calendar boundary; for allTime uses earliest date
  /// 获取当前选中范围的开始日期
  /// 周/月返回日历边界；全部时间使用最早日期
  DateTime _getRangeStartDate() {
    return _selectedRange.startDate ?? _getEarliestDate();
  }

  /// Check if a habit existed on a given date (createdAt is null or <= date)
  /// 检查习惯在给定日期是否已存在（createdAt 为 null 或 <= 该日期）
  bool _habitExistedOnDate(Habit habit, DateTime date) {
    if (habit.createdAt == null) return true; // legacy habit, assume always existed
    final createdDay = DateTime(habit.createdAt!.year, habit.createdAt!.month, habit.createdAt!.day);
    return !createdDay.isAfter(date);
  }

  /// Check if a specific habit was completed on a specific date - O(1) lookup
  /// 检查某个习惯在特定日期是否已完成——O(1) 查找
  bool wasHabitCompletedOnDate(String habitId, DateTime date) {
    final normalizedDates = _normalizedHistories[habitId];
    if (normalizedDates == null) return false;
    return normalizedDates.contains(_dateToKey(date));
  }

  /// Initialize progress data
  /// 初始化进度数据
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
  /// 刷新所有数据
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _fetchAllHistory();
    _recalculateAll();
    _isLoading = false;
    notifyListeners();
  }

  /// Fetch completion history for all habits from Firestore
  /// 从 Firestore 获取所有习惯的完成历史
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
  /// 删除不再存在的习惯的历史记录
  /// 防止内存无限增长
  void _pruneOldHistories() {
    final currentHabitIds = _habits.map((h) => h.id).toSet();
    _habitHistories.removeWhere((id, _) => !currentHabitIds.contains(id));
    _normalizedHistories.removeWhere((id, _) => !currentHabitIds.contains(id));
  }

  /// Recalculate all statistics after data refresh
  /// 数据刷新后重新计算所有统计信息
  void _recalculateAll() {
    _calculateAllStats();
    // notifyListeners() already called in _calculateAllStats
  }

  /// Calculate weekly heatmap using real history with O(1) lookups
  /// 使用真实历史数据和 O(1) 查找计算每周热力图
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

  /// Calculate trend data using real history with O(1) lookups
  /// 使用真实历史数据和 O(1) 查找计算趋势数据
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

  /// Calculate top and bottom performing habits
  /// 计算表现最佳和最差的习惯
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

  /// Calculate achievements based on current habit data and stats
  /// 根据当前习惯数据和统计信息计算成就
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
  /// 登出时清除所有用户数据
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
  /// 计算趋势变化百分比
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
/// 用于计算习惯表现的辅助类
class _HabitPerfData {
  final Habit habit;
  final int completions;
  final int totalDays;
  final double successRate;

  /// Create a habit performance data object
  /// 创建习惯表现数据对象
  _HabitPerfData({
    required this.habit,
    required this.completions,
    required this.totalDays,
    required this.successRate,
  });
}
