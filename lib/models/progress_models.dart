// =============================================================================
// progress_models.dart — Progress Analytics Data Models
// 进度分析数据模型
//
// Models for the progress/analytics screen. Includes DateRange enum,
// ProgressStats (overall completion metrics), CategoryStats (per-category
// breakdown), Achievement badges, TrendData (time-series), and
// HeatmapData (calendar visualisation). Used by ProgressProvider.
//
// 进度/分析界面的数据模型。包括 DateRange 枚举、
// ProgressStats（整体完成指标）、CategoryStats（按类别细分）、
// Achievement 徽章、TrendData（时间序列）和
// HeatmapData（日历可视化）。由 ProgressProvider 使用。
// =============================================================================

import 'package:flutter/material.dart';
import 'habit.dart';
import 'habit_category.dart';

/// Date range for progress filtering
/// 进度过滤的日期范围
enum DateRange { thisWeek, thisMonth, allTime }

extension DateRangeExtension on DateRange {
  /// Get display name for the date range
  /// 获取日期范围的显示名称
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

  /// Returns the start date for this range (inclusive).
  /// null means "all time" - the provider computes from earliest history.
  /// 返回此范围的起始日期（包含）。
  /// null 表示"所有时间"——由 provider 从最早历史计算。
  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case DateRange.thisWeek:
        // Monday of the current week
        return DateTime(now.year, now.month, now.day - (now.weekday - 1));
      case DateRange.thisMonth:
        // 1st of the current month
        return DateTime(now.year, now.month, 1);
      case DateRange.allTime:
        return null;
    }
  }
}

/// Overall progress statistics
/// 整体进度统计数据
class ProgressStats {
  final double completionRate; // 0.0 to 1.0
  final int daysTracked;
  final int bestStreak;
  final int totalHabits;
  final int completedToday;
  final int totalToday;

  /// Creates ProgressStats with all required metrics
  /// 使用所有必需指标创建 ProgressStats
  const ProgressStats({
    required this.completionRate,
    required this.daysTracked,
    required this.bestStreak,
    required this.totalHabits,
    required this.completedToday,
    required this.totalToday,
  });

  /// Get formatted completion percentage string
  /// 获取格式化的完成百分比字符串
  String get completionPercentage => '${(completionRate * 100).toInt()}%';
}

/// Category breakdown data
/// 按类别分解的数据
class CategoryBreakdown {
  final HabitCategory category;
  final int habitCount;
  final double percentage; // 0.0 to 1.0

  /// Creates a CategoryBreakdown with category, count, and percentage
  /// 使用类别、数量和百分比创建 CategoryBreakdown
  const CategoryBreakdown({
    required this.category,
    required this.habitCount,
    required this.percentage,
  });
}

/// Weekly heatmap data for a single day
/// 单日的每周热力图数据
class DayHeatmapData {
  final DateTime date;
  final int completed;
  final int total;
  final double completionRate; // 0.0 to 1.0

  /// Creates a DayHeatmapData with date and completion info
  /// 使用日期和完成信息创建 DayHeatmapData
  const DayHeatmapData({
    required this.date,
    required this.completed,
    required this.total,
    required this.completionRate,
  });

  /// Check if this data point is for today
  /// 检查此数据点是否是今天的
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get the day number as a string
  /// 获取日期号数的字符串
  String get dayNumber => date.day.toString();

  /// Get completion text in "completed/total" format
  /// 获取"已完成/总数"格式的完成文本
  String get completionText => '$completed/$total';
}

/// Trend chart data point
/// 趋势图表数据点
class TrendDataPoint {
  final DateTime date;
  final double completionRate; // 0.0 to 1.0

  /// Creates a TrendDataPoint with date and completion rate
  /// 使用日期和完成率创建 TrendDataPoint
  const TrendDataPoint({required this.date, required this.completionRate});
}

/// Habit performance ranking
/// 习惯表现排名
class HabitPerformance {
  final Habit habit;
  final double successRate; // 0.0 to 1.0
  final int completions;
  final int totalDays;

  /// Creates a HabitPerformance with habit data and success metrics
  /// 使用习惯数据和成功指标创建 HabitPerformance
  const HabitPerformance({
    required this.habit,
    required this.successRate,
    required this.completions,
    required this.totalDays,
  });

  /// Get formatted success percentage string
  /// 获取格式化的成功百分比字符串
  String get successPercentage => '${(successRate * 100).toInt()}%';
}

/// AI weekly summary
/// AI 每周总结
class WeeklySummary {
  final String summary;
  final String periodLabel; // "This Week" or "This Month"
  final DateTime generatedAt;
  final List<double> last7DaysTrend; // Mini chart data

  /// Creates a WeeklySummary with AI-generated content
  /// 使用 AI 生成的内容创建 WeeklySummary
  const WeeklySummary({
    required this.summary,
    required this.periodLabel,
    required this.generatedAt,
    required this.last7DaysTrend,
  });

  /// Check if this summary is stale (older than 24 hours)
  /// 检查此总结是否过期（超过24小时）
  bool get isStale {
    final age = DateTime.now().difference(generatedAt);
    return age.inHours >= 24;
  }
}

/// Achievement badge
/// 成就徽章
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

  /// Creates an Achievement with all required and optional fields
  /// 使用所有必需和可选字段创建 Achievement
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

  /// Progress towards the achievement (0.0 to 1.0, clamped)
  /// 成就进度（0.0 到 1.0，已限制范围）
  double get progress {
    if (targetValue <= 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Get progress text for display
  /// 获取用于显示的进度文本
  String get progressText {
    if (isUnlocked) {
      return 'Unlocked';
    }
    return '$currentValue of $targetValue';
  }

  /// Get formatted unlock date text
  /// 获取格式化的解锁日期文本
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
      final monthIndex = unlockedAt!.month;
      if (monthIndex < 1 || monthIndex > 12) return 'Unknown';
      return '${months[monthIndex - 1]} ${unlockedAt!.day}, ${unlockedAt!.year}';
    }
  }

  /// Get achievement-specific tips based on category
  /// 根据类别获取成就相关的技巧
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
/// 成就类别
enum AchievementCategory {
  streak,
  completion,
  ai,
  category,
  consistency,
  special,
}

extension AchievementCategoryExtension on AchievementCategory {
  /// Get display name for the achievement category
  /// 获取成就类别的显示名称
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

  /// Get color for the achievement category based on theme
  /// 根据主题获取成就类别的颜色
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
