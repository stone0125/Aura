import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/habit.dart';
import '../models/habit_stats.dart';
import '../services/firestore_service.dart';

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

  final FirestoreService _firestoreService = FirestoreService();

  /// Load habit details with real history
  Future<void> loadHabitDetails(Habit habit) async {
    _habit = habit;
    notifyListeners();

    await _loadData();

    // Load AI insight if needed
    if (_aiInsight == null || _aiInsight!.isStale) {
      await _loadAIInsight();
    }
  }

  /// Load real data from Firestore
  Future<void> _loadData() async {
    if (_habit == null) return;

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
    }
    notifyListeners();
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
      // Current Streak
      // Check if today or yesterday is in list (if no, streak is 0)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      if (uniqueDates.contains(today)) {
        // Count backwards
        currentStreak = 1;
        var checkDate = yesterday;
        while (uniqueDates.contains(checkDate)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      } else if (uniqueDates.contains(yesterday)) {
        currentStreak =
            0; // Or does streak persist? Usually if you miss today, streak is technically valid until day ends?
        // Let's assume if it contains yesterday, streak is valid.
        var checkDate = yesterday;
        while (uniqueDates.contains(checkDate)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      } else {
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
      bestDay = dayNames[bestDayNum - 1];
    }

    _stats = HabitStats(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalCompletions: history.length,
      completionRate: completionRate,
      bestDay: bestDay,
      bestTime: 'Morning', // Would need time data to calculate
    );
  }

  /// Load AI insight from Cloud Function
  Future<void> _loadAIInsight() async {
    if (_habit == null) return;

    _isLoadingInsight = true;
    notifyListeners();

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateHabitInsight');

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

      final data = result.data;
      _aiInsight = AIInsight(
        text: data['text'] ?? 'Keep going!',
        confidence: data['confidence'] ?? 'medium',
        generatedAt: DateTime.now(),
        supportingIcon: data['icon'] ?? 'trending_up',
      );
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
      notifyListeners();
    }
  }

  /// Refresh AI insight
  Future<void> refreshAIInsight() async {
    await _loadAIInsight();
  }

  /// Mark habit as complete for today
  Future<void> completeHabit() async {
    if (_habit == null) return;

    await _firestoreService.toggleHabitCompletion(
      _habit!,
    ); // This handles history logging we added
    await _loadData(); // Reload to update UI
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

  /// Check if completion exists for a specific date
  bool isCompletedOn(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _calendarData[dateKey] ?? false;
  }
}
