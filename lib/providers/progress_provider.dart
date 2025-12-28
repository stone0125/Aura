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

  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();
  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();

  /// Called by ProxyProvider when habits change
  void updateHabits(List<Habit> habits) {
    _habits = habits;
    _calculateAllStats();
  }

  /// Change selected date range
  void setDateRange(DateRange range) {
    _selectedRange = range;
    _calculateAllStats();
    notifyListeners();
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
    final completionRate = totalHabits > 0 ? completedToday / totalHabits : 0.0;

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
      // In a real production app with many habits, we would optimize this
      // (e.g. collection group query or storing stats on the habit doc).
      // For now, parallel fetch is acceptable.
      await Future.wait(
        _habits.map((h) async {
          final history = await _firestoreService.getHabitHistory(h.id);
          _habitHistories[h.id] = history;
        }),
      );
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
  }

  void _recalculateAll() {
    _calculateAllStats();
    notifyListeners();
  }

  // Updated Heatmap Calculation using Real History
  void _calculateWeeklyHeatmap() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    _weeklyHeatmap = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));

      int completed = 0;
      int total = _habits.length;

      for (var h in _habits) {
        final history = _habitHistories[h.id] ?? [];
        // Check if history contains this date
        if (history.any(
          (d) =>
              d.year == date.year && d.month == date.month && d.day == date.day,
        )) {
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

  // Updated Trend Data using Real History
  void _calculateTrendData() {
    int days = 7;
    if (_selectedRange == DateRange.thisMonth) days = 30;

    final now = DateTime.now();

    _trendData = List.generate(days, (index) {
      final date = now.subtract(Duration(days: days - 1 - index));

      int completed = 0;
      int total = _habits
          .length; // Assuming total number of habits was constant (Simplification)

      if (total > 0) {
        for (var h in _habits) {
          final history = _habitHistories[h.id] ?? [];
          if (history.any(
            (d) =>
                d.year == date.year &&
                d.month == date.month &&
                d.day == date.day,
          )) {
            completed++;
          }
        }
      }

      return TrendDataPoint(
        date: date,
        completionRate: total > 0 ? completed / total : 0.0,
      );
    });
  }

  void _calculatePerformers() {
    // Calculate actual performance based on history within selected range
    final now = DateTime.now();
    final rangeDays = _selectedRange.days ?? 30;
    final rangeStart = now.subtract(Duration(days: rangeDays));

    // Build performance data for each habit
    List<_HabitPerfData> perfData = [];

    for (var h in _habits) {
      final history = _habitHistories[h.id] ?? [];
      // Count completions within range
      final completionsInRange = history
          .where((d) => d.isAfter(rangeStart) || d.isAtSameMomentAs(rangeStart))
          .length;

      final successRate = rangeDays > 0 ? completionsInRange / rangeDays : 0.0;
      perfData.add(
        _HabitPerfData(
          habit: h,
          completions: completionsInRange,
          totalDays: rangeDays,
          successRate: successRate.clamp(0.0, 1.0),
        ),
      );
    }

    // Sort by success rate descending for top performers
    perfData.sort((a, b) => b.successRate.compareTo(a.successRate));

    _topPerformers = perfData
        .take(3)
        .map(
          (p) => HabitPerformance(
            habit: p.habit,
            successRate: p.successRate,
            completions: p.completions,
            totalDays: p.totalDays,
          ),
        )
        .toList();

    // Bottom performers - sort ascending
    perfData.sort((a, b) => a.successRate.compareTo(b.successRate));

    _bottomPerformers = perfData
        .take(3)
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

  /// Calculate trend percentage change
  double getTrendChange() {
    if (_trendData.length < 2) return 0.0;

    final days = _selectedRange.days ?? 30;
    final halfPoint = days ~/ 2;

    if (_trendData.length <= halfPoint) return 0.0;

    final firstHalfAvg =
        _trendData
            .take(halfPoint)
            .map((d) => d.completionRate)
            .reduce((a, b) => a + b) /
        halfPoint;

    final secondHalfAvg =
        _trendData
            .skip(halfPoint)
            .map((d) => d.completionRate)
            .reduce((a, b) => a + b) /
        (_trendData.length - halfPoint);

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
