import 'package:flutter/material.dart';
import '../models/progress_models.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';

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

  /// Initialize progress data
  Future<void> initialize() async {
    await loadProgressData();
  }

  /// Change selected date range
  Future<void> setDateRange(DateRange range) async {
    _selectedRange = range;
    notifyListeners();
    await loadProgressData();
  }

  /// Load all progress data
  Future<void> loadProgressData() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    _loadMockStats();
    _loadMockCategoryBreakdown();
    _loadMockWeeklyHeatmap();
    _loadMockTrendData();
    _loadMockPerformers();
    _loadMockAchievements();
    await _loadMockWeeklySummary();

    _isLoading = false;
    notifyListeners();
  }

  /// Load mock statistics
  void _loadMockStats() {
    _stats = const ProgressStats(
      completionRate: 0.85,
      daysTracked: 42,
      bestStreak: 14,
      totalHabits: 8,
      completedToday: 5,
      totalToday: 8,
    );
  }

  /// Load mock category breakdown
  void _loadMockCategoryBreakdown() {
    _categoryBreakdown = [
      const CategoryBreakdown(
        category: HabitCategory.health,
        habitCount: 3,
        percentage: 0.375,
      ),
      const CategoryBreakdown(
        category: HabitCategory.fitness,
        habitCount: 2,
        percentage: 0.25,
      ),
      const CategoryBreakdown(
        category: HabitCategory.mindfulness,
        habitCount: 2,
        percentage: 0.25,
      ),
      const CategoryBreakdown(
        category: HabitCategory.learning,
        habitCount: 1,
        percentage: 0.125,
      ),
    ];
  }

  /// Load mock weekly heatmap
  void _loadMockWeeklyHeatmap() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    _weeklyHeatmap = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final completed = index < now.weekday ? (5 + (index % 3)) : 0;
      final total = 8;
      return DayHeatmapData(
        date: date,
        completed: completed,
        total: total,
        completionRate: completed / total,
      );
    });
  }

  /// Load mock trend data
  void _loadMockTrendData() {
    final now = DateTime.now();
    final days = _selectedRange.days ?? 30;

    _trendData = List.generate(days, (index) {
      final date = now.subtract(Duration(days: days - 1 - index));
      // Simulate varying completion rates with some randomness
      final baseRate = 0.75 + (index % 7) * 0.05;
      final variance = (index % 3) * 0.05;
      final rate = (baseRate + variance).clamp(0.0, 1.0);

      return TrendDataPoint(
        date: date,
        completionRate: rate,
      );
    });
  }

  /// Load mock performers
  void _loadMockPerformers() {
    // Mock habits for top performers
    final topHabits = [
      const Habit(
        id: '1',
        name: 'Morning Meditation',
        category: HabitCategory.mindfulness,
        streak: 21,
        isCompleted: true,
      ),
      const Habit(
        id: '2',
        name: 'Daily Reading',
        category: HabitCategory.learning,
        streak: 18,
        isCompleted: true,
      ),
      const Habit(
        id: '3',
        name: 'Drink Water',
        category: HabitCategory.health,
        streak: 14,
        isCompleted: true,
      ),
    ];

    _topPerformers = [
      HabitPerformance(
        habit: topHabits[0],
        successRate: 0.95,
        completions: 38,
        totalDays: 40,
      ),
      HabitPerformance(
        habit: topHabits[1],
        successRate: 0.90,
        completions: 36,
        totalDays: 40,
      ),
      HabitPerformance(
        habit: topHabits[2],
        successRate: 0.88,
        completions: 35,
        totalDays: 40,
      ),
    ];

    // Mock habits for bottom performers
    final bottomHabits = [
      const Habit(
        id: '4',
        name: 'Evening Journaling',
        category: HabitCategory.mindfulness,
        streak: 3,
        isCompleted: false,
      ),
      const Habit(
        id: '5',
        name: 'Afternoon Walk',
        category: HabitCategory.fitness,
        streak: 5,
        isCompleted: false,
      ),
    ];

    _bottomPerformers = [
      HabitPerformance(
        habit: bottomHabits[0],
        successRate: 0.45,
        completions: 18,
        totalDays: 40,
      ),
      HabitPerformance(
        habit: bottomHabits[1],
        successRate: 0.60,
        completions: 24,
        totalDays: 40,
      ),
    ];
  }

  /// Load mock achievements
  void _loadMockAchievements() {
    final now = DateTime.now();

    _achievements = [
      // Streak Achievements
      Achievement(
        id: 'first_step',
        name: 'First Step',
        description: 'Complete your first habit',
        icon: Icons.directions_walk_rounded,
        category: AchievementCategory.streak,
        targetValue: 1,
        currentValue: 1,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 42)),
      ),
      Achievement(
        id: 'week_warrior',
        name: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: Icons.emoji_events_rounded,
        category: AchievementCategory.streak,
        targetValue: 7,
        currentValue: 7,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 7)),
      ),
      Achievement(
        id: 'month_master',
        name: 'Month Master',
        description: 'Maintain a 30-day streak',
        icon: Icons.military_tech_rounded,
        category: AchievementCategory.streak,
        targetValue: 30,
        currentValue: 14,
        isUnlocked: false,
      ),
      Achievement(
        id: 'hundred_days',
        name: 'Hundred Days',
        description: 'Maintain a 100-day streak',
        icon: Icons.workspace_premium_rounded,
        category: AchievementCategory.streak,
        targetValue: 100,
        currentValue: 14,
        isUnlocked: false,
      ),

      // Completion Achievements
      Achievement(
        id: 'beginner',
        name: 'Beginner',
        description: 'Complete 10 total habits',
        icon: Icons.star_outline_rounded,
        category: AchievementCategory.completion,
        targetValue: 10,
        currentValue: 10,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 35)),
      ),
      Achievement(
        id: 'committed',
        name: 'Committed',
        description: 'Complete 50 total habits',
        icon: Icons.star_half_rounded,
        category: AchievementCategory.completion,
        targetValue: 50,
        currentValue: 50,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 15)),
      ),
      Achievement(
        id: 'century_club',
        name: 'Century Club',
        description: 'Complete 100 total habits',
        icon: Icons.star_rounded,
        category: AchievementCategory.completion,
        targetValue: 100,
        currentValue: 87,
        isUnlocked: false,
      ),

      // AI Achievements
      Achievement(
        id: 'ai_assisted',
        name: 'AI Assisted',
        description: 'Add your first AI-suggested habit',
        icon: Icons.psychology_rounded,
        category: AchievementCategory.ai,
        targetValue: 1,
        currentValue: 1,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 20)),
      ),
      Achievement(
        id: 'pattern_master',
        name: 'Pattern Master',
        description: 'Follow AI insights 5 times',
        icon: Icons.analytics_rounded,
        category: AchievementCategory.ai,
        targetValue: 5,
        currentValue: 3,
        isUnlocked: false,
      ),

      // Category Achievements
      Achievement(
        id: 'health_hero',
        name: 'Health Hero',
        description: 'Complete all health habits for 30 days',
        icon: Icons.favorite_rounded,
        category: AchievementCategory.category,
        targetValue: 30,
        currentValue: 12,
        isUnlocked: false,
      ),
      Achievement(
        id: 'mindful_master',
        name: 'Mindful Master',
        description: 'Complete all mindfulness habits for 30 days',
        icon: Icons.spa_rounded,
        category: AchievementCategory.category,
        targetValue: 30,
        currentValue: 8,
        isUnlocked: false,
      ),

      // Consistency Achievements
      Achievement(
        id: 'perfect_week',
        name: 'Perfect Week',
        description: 'Complete 100% of habits for 7 days',
        icon: Icons.check_circle_rounded,
        category: AchievementCategory.consistency,
        targetValue: 7,
        currentValue: 4,
        isUnlocked: false,
      ),
      Achievement(
        id: 'early_bird',
        name: 'Early Bird',
        description: 'Complete morning habits for 14 days',
        icon: Icons.wb_sunny_rounded,
        category: AchievementCategory.consistency,
        targetValue: 14,
        currentValue: 14,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 1)),
      ),

      // Special Achievements
      Achievement(
        id: 'balanced_life',
        name: 'Balanced Life',
        description: 'Have habits in all 5 categories',
        icon: Icons.balance_rounded,
        category: AchievementCategory.special,
        targetValue: 5,
        currentValue: 4,
        isUnlocked: false,
      ),
      Achievement(
        id: 'comeback_kid',
        name: 'Comeback Kid',
        description: 'Return after 7-day absence',
        icon: Icons.refresh_rounded,
        category: AchievementCategory.special,
        targetValue: 1,
        currentValue: 0,
        isUnlocked: false,
      ),
    ];
  }

  /// Load mock weekly summary
  Future<void> _loadMockWeeklySummary() async {
    // Simulate AI generation delay
    await Future.delayed(const Duration(milliseconds: 500));

    final periodLabel = _selectedRange == DateRange.thisWeek
        ? 'This Week'
        : _selectedRange == DateRange.thisMonth
            ? 'This Month'
            : 'All Time';

    // Generate different summaries based on completion rate
    String summary;
    if (_stats!.completionRate >= 0.9) {
      summary =
          "Excellent week! You improved by 15% compared to last period, reaching an ${_stats!.completionPercentage} success rate. Your consistency is building real momentum. I noticed you're particularly strong on weekdays but could optimize weekend habits. Consider scheduling easier habits for Saturday and Sunday to maintain your streak.";
    } else if (_stats!.completionRate >= 0.7) {
      summary =
          "Solid effort this period with ${_stats!.completionPercentage} completion. You had several perfect days, which is fantastic! Your morning routine is rock-solid at 95% success. However, evening habits need attention—you completed only 60% of them. Try setting an earlier reminder or stacking evening habits together.";
    } else {
      summary =
          "This period had ups and downs (${_stats!.completionPercentage} completion), but don't be discouraged—progress isn't always linear. You showed resilience by bouncing back after tough days. Your ${_stats!.bestStreak}-day streak proves you can be consistent when it matters. Let's focus on one habit at a time to rebuild momentum.";
    }

    _weeklySummary = WeeklySummary(
      summary: summary,
      periodLabel: periodLabel,
      generatedAt: DateTime.now(),
      last7DaysTrend: _weeklyHeatmap.map((d) => d.completionRate).toList(),
    );
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadProgressData();
  }

  /// Calculate trend percentage change
  double getTrendChange() {
    if (_trendData.length < 2) return 0.0;

    final days = _selectedRange.days ?? 30;
    final halfPoint = days ~/ 2;

    if (_trendData.length <= halfPoint) return 0.0;

    final firstHalfAvg = _trendData
            .take(halfPoint)
            .map((d) => d.completionRate)
            .reduce((a, b) => a + b) /
        halfPoint;

    final secondHalfAvg = _trendData
            .skip(halfPoint)
            .map((d) => d.completionRate)
            .reduce((a, b) => a + b) /
        (_trendData.length - halfPoint);

    return ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100;
  }
}
