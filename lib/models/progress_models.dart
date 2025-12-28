import 'package:flutter/material.dart';
import 'habit.dart';
import 'habit_category.dart';

/// Date range for progress filtering
enum DateRange { thisWeek, thisMonth, allTime }

extension DateRangeExtension on DateRange {
  String get displayName {
    switch (this) {
      case DateRange.thisWeek:
        return 'Week';
      case DateRange.thisMonth:
        return 'Month';
      case DateRange.allTime:
        return 'All';
    }
  }

  int? get days {
    switch (this) {
      case DateRange.thisWeek:
        return 7;
      case DateRange.thisMonth:
        return 30;
      case DateRange.allTime:
        return null;
    }
  }
}

/// Overall progress statistics
class ProgressStats {
  final double completionRate; // 0.0 to 1.0
  final int daysTracked;
  final int bestStreak;
  final int totalHabits;
  final int completedToday;
  final int totalToday;

  const ProgressStats({
    required this.completionRate,
    required this.daysTracked,
    required this.bestStreak,
    required this.totalHabits,
    required this.completedToday,
    required this.totalToday,
  });

  String get completionPercentage => '${(completionRate * 100).toInt()}%';
}

/// Category breakdown data
class CategoryBreakdown {
  final HabitCategory category;
  final int habitCount;
  final double percentage; // 0.0 to 1.0

  const CategoryBreakdown({
    required this.category,
    required this.habitCount,
    required this.percentage,
  });
}

/// Weekly heatmap data for a single day
class DayHeatmapData {
  final DateTime date;
  final int completed;
  final int total;
  final double completionRate; // 0.0 to 1.0

  const DayHeatmapData({
    required this.date,
    required this.completed,
    required this.total,
    required this.completionRate,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String get dayNumber => date.day.toString();

  String get completionText => '$completed/$total';
}

/// Trend chart data point
class TrendDataPoint {
  final DateTime date;
  final double completionRate; // 0.0 to 1.0

  const TrendDataPoint({required this.date, required this.completionRate});
}

/// Habit performance ranking
class HabitPerformance {
  final Habit habit;
  final double successRate; // 0.0 to 1.0
  final int completions;
  final int totalDays;

  const HabitPerformance({
    required this.habit,
    required this.successRate,
    required this.completions,
    required this.totalDays,
  });

  String get successPercentage => '${(successRate * 100).toInt()}%';
}

/// AI weekly summary
class WeeklySummary {
  final String summary;
  final String periodLabel; // "This Week" or "This Month"
  final DateTime generatedAt;
  final List<double> last7DaysTrend; // Mini chart data

  const WeeklySummary({
    required this.summary,
    required this.periodLabel,
    required this.generatedAt,
    required this.last7DaysTrend,
  });

  bool get isStale {
    final age = DateTime.now().difference(generatedAt);
    return age.inHours >= 24;
  }
}

/// Achievement badge
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.isUnlocked,
    this.unlockedAt,
  });

  double get progress => currentValue / targetValue;

  String get progressText {
    if (isUnlocked) {
      return 'Unlocked';
    }
    return '$currentValue of $targetValue';
  }

  String get unlockedDateText {
    if (unlockedAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(unlockedAt!);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[unlockedAt!.month - 1]} ${unlockedAt!.day}, ${unlockedAt!.year}';
    }
  }

  List<String> get tips {
    // Return achievement-specific tips
    switch (category) {
      case AchievementCategory.streak:
        return [
          'Set a daily reminder to stay on track',
          'Start with small, achievable habits',
          'Never miss twice in a row',
        ];
      case AchievementCategory.completion:
        return [
          'Focus on consistency, not perfection',
          'Celebrate small wins along the way',
          'Track your progress daily',
        ];
      case AchievementCategory.ai:
        return [
          'Review AI insights regularly',
          'Apply suggested patterns to your routine',
          'Use AI tips to improve consistency',
        ];
      case AchievementCategory.category:
        return [
          'Balance habits across all categories',
          'Start with one category and expand',
          'Stack habits from the same category',
        ];
      case AchievementCategory.consistency:
        return [
          'Prepare for obstacles in advance',
          'Use habit stacking techniques',
          'Set up your environment for success',
        ];
      case AchievementCategory.special:
        return [
          'Experiment with different habit types',
          'Find what works best for you',
          'Stay flexible and adapt',
        ];
    }
  }
}

/// Achievement category
enum AchievementCategory {
  streak,
  completion,
  ai,
  category,
  consistency,
  special,
}

extension AchievementCategoryExtension on AchievementCategory {
  String get displayName {
    switch (this) {
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.completion:
        return 'Completion';
      case AchievementCategory.ai:
        return 'AI';
      case AchievementCategory.category:
        return 'Category';
      case AchievementCategory.consistency:
        return 'Consistency';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  Color getColor(bool isDark) {
    switch (this) {
      case AchievementCategory.streak:
        return isDark ? const Color(0xFFFF8A80) : const Color(0xFFFF6B6B);
      case AchievementCategory.completion:
        return isDark ? const Color(0xFF82B1FF) : const Color(0xFFB8D4E8);
      case AchievementCategory.ai:
        return isDark ? const Color(0xFF69F0AE) : const Color(0xFFA8E6CF);
      case AchievementCategory.category:
        return isDark ? const Color(0xFFB388FF) : const Color(0xFFE3D5FF);
      case AchievementCategory.consistency:
        return isDark ? const Color(0xFFFF80AB) : const Color(0xFFFFD3E1);
      case AchievementCategory.special:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF39C12);
    }
  }
}
