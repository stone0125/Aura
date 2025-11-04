import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_stats.dart';

/// Provider for managing habit detail data
class HabitDetailProvider with ChangeNotifier {
  Habit? _habit;
  HabitStats? _stats;
  List<HabitCompletion> _completions = [];
  AIInsight? _aiInsight;
  bool _isLoadingInsight = false;
  Map<DateTime, bool> _calendarData = {};

  // Getters
  Habit? get habit => _habit;
  HabitStats? get stats => _stats;
  List<HabitCompletion> get completions => _completions;
  AIInsight? get aiInsight => _aiInsight;
  bool get isLoadingInsight => _isLoadingInsight;
  Map<DateTime, bool> get calendarData => _calendarData;

  /// Check if habit was completed today
  bool get isCompletedToday {
    return _completions.any((c) => c.isToday);
  }

  /// Load habit details
  Future<void> loadHabitDetails(Habit habit) async {
    _habit = habit;
    _loadMockData();
    notifyListeners();

    // Load AI insight if needed
    if (_aiInsight == null || _aiInsight!.isStale) {
      await _loadAIInsight();
    }
  }

  /// Load mock data for demonstration
  void _loadMockData() {
    if (_habit == null) return;

    // Mock statistics
    _stats = HabitStats(
      currentStreak: _habit!.streak,
      longestStreak: 21,
      totalCompletions: 87,
      completionRate: 85.2,
      bestDay: 'Tuesday',
      bestTime: '9:15 AM',
    );

    // Mock completions
    final now = DateTime.now();
    _completions = [
      HabitCompletion(
        id: '1',
        date: now,
        time: '9:15 AM',
        method: CompletionMethod.manual,
        notes: '',
      ),
      HabitCompletion(
        id: '2',
        date: now.subtract(const Duration(days: 1)),
        time: '9:30 AM',
        method: CompletionMethod.reminder,
        notes: '',
      ),
      HabitCompletion(
        id: '3',
        date: now.subtract(const Duration(days: 2)),
        time: '10:00 AM',
        method: CompletionMethod.manual,
        notes: '',
      ),
      HabitCompletion(
        id: '4',
        date: now.subtract(const Duration(days: 3)),
        time: '9:00 AM',
        method: CompletionMethod.quickTap,
        notes: '',
      ),
      HabitCompletion(
        id: '5',
        date: now.subtract(const Duration(days: 4)),
        time: '9:45 AM',
        method: CompletionMethod.manual,
        notes: '',
      ),
    ];

    // Mock calendar data (last 30 days)
    _calendarData = {};
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      // 85% completion rate simulation
      final isCompleted = (i % 7) != 0 && (i % 5) != 4;
      _calendarData[DateTime(date.year, date.month, date.day)] = isCompleted;
    }
  }

  /// Load AI insight
  Future<void> _loadAIInsight() async {
    _isLoadingInsight = true;
    notifyListeners();

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock AI insight
    _aiInsight = AIInsight(
      text: 'You complete this habit 90% of the time after breakfast 🍳',
      confidence: 'high',
      generatedAt: DateTime.now(),
      supportingIcon: 'coffee',
    );

    _isLoadingInsight = false;
    notifyListeners();
  }

  /// Refresh AI insight
  Future<void> refreshAIInsight() async {
    await _loadAIInsight();
  }

  /// Mark habit as complete for today
  Future<void> completeHabit() async {
    if (_habit == null || isCompletedToday) return;

    // Create new completion
    final now = DateTime.now();
    final timeStr =
        '${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    final completion = HabitCompletion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: now,
      time: timeStr,
      method: CompletionMethod.manual,
      notes: '',
    );

    _completions.insert(0, completion);

    // Update stats
    _stats = HabitStats(
      currentStreak: _stats!.currentStreak + 1,
      longestStreak: _stats!.currentStreak + 1 > _stats!.longestStreak
          ? _stats!.currentStreak + 1
          : _stats!.longestStreak,
      totalCompletions: _stats!.totalCompletions + 1,
      completionRate: _stats!.completionRate, // Recalculate in real app
      bestDay: _stats!.bestDay,
      bestTime: _stats!.bestTime,
    );

    // Update calendar
    _calendarData[DateTime(now.year, now.month, now.day)] = true;

    notifyListeners();
  }

  /// Undo today's completion
  Future<void> undoCompletion() async {
    if (_habit == null || !isCompletedToday) return;

    // Remove today's completion
    _completions.removeWhere((c) => c.isToday);

    // Update stats
    _stats = HabitStats(
      currentStreak: _stats!.currentStreak - 1,
      longestStreak: _stats!.longestStreak,
      totalCompletions: _stats!.totalCompletions - 1,
      completionRate: _stats!.completionRate,
      bestDay: _stats!.bestDay,
      bestTime: _stats!.bestTime,
    );

    // Update calendar
    final now = DateTime.now();
    _calendarData[DateTime(now.year, now.month, now.day)] = false;

    notifyListeners();
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

      points.add(ChartDataPoint(
        date: dateKey,
        value: isCompleted ? 1.0 : 0.0,
        isCompleted: isCompleted,
      ));
    }

    return points;
  }

  /// Check if completion exists for a specific date
  bool isCompletedOn(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _calendarData[dateKey] ?? false;
  }
}
