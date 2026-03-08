// =============================================================================
// habit_stats.dart — Habit Statistics Model
// 习惯统计数据模型
//
// Immutable data class holding computed statistics for a single habit:
// current streak, longest streak, total completions, completion rate,
// best day of week, and best time of day.
//
// 保存单个习惯计算统计数据的不可变数据类：
// 当前连续天数、最长连续天数、总完成次数、完成率、
// 最佳星期几和最佳时间段。
// =============================================================================

/// Habit statistics model
/// 习惯统计数据模型
class HabitStats {
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final double completionRate;
  final String? bestDay;
  final String? bestTime;

  /// Creates a HabitStats instance with the given statistics
  /// 使用给定统计数据创建 HabitStats 实例
  const HabitStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    required this.completionRate,
    this.bestDay,
    this.bestTime,
  });

  /// Calculate if current streak equals longest (record)
  /// 计算当前连续天数是否等于最长记录
  bool get isRecord => currentStreak > 0 && currentStreak == longestStreak;

  /// Format completion rate as percentage string
  /// 将完成率格式化为百分比字符串
  String get completionRateFormatted => '${completionRate.toStringAsFixed(0)}%';
}

/// Habit completion entry
/// 习惯完成记录条目
class HabitCompletion {
  final String id;
  final DateTime date;
  final String? time;
  final CompletionMethod method;
  final String? notes;

  /// Creates a HabitCompletion instance with the given data
  /// 使用给定数据创建 HabitCompletion 实例
  const HabitCompletion({
    required this.id,
    required this.date,
    this.time,
    required this.method,
    this.notes,
  });

  /// Check if this completion is for today
  /// 检查此完成记录是否是今天的
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get formatted date string
  /// 获取格式化的日期字符串
  String get formattedDate {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (isToday) {
      return time != null ? 'Today, $time' : 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return time != null ? 'Yesterday, $time' : 'Yesterday';
    } else {
      // Format as "Nov 3, 2:30 PM"
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
        'Dec'
      ];
      final monthIndex = date.month;
      if (monthIndex < 1 || monthIndex > 12) return 'Unknown';
      final month = months[monthIndex - 1];
      return time != null
          ? '$month ${date.day}, $time'
          : '$month ${date.day}';
    }
  }
}

/// How the habit was completed
/// 习惯的完成方式
enum CompletionMethod {
  manual,
  reminder,
  quickTap,
}

/// AI insight for a habit
/// 习惯的 AI 洞察
class AIInsight {
  final String text;
  final String confidence;
  final DateTime generatedAt;
  final String? supportingIcon;

  /// Creates an AIInsight instance with the given data
  /// 使用给定数据创建 AIInsight 实例
  const AIInsight({
    required this.text,
    required this.confidence,
    required this.generatedAt,
    this.supportingIcon,
  });

  /// Check if insight is stale (>24 hours old)
  /// 检查洞察是否过期（超过24小时）
  bool get isStale {
    final now = DateTime.now();
    final age = now.difference(generatedAt);
    return age.inHours >= 24;
  }
}

/// Chart data point
/// 图表数据点
class ChartDataPoint {
  final DateTime date;
  final double value;
  final bool isCompleted;

  /// Creates a ChartDataPoint with date, value, and completion status
  /// 使用日期、数值和完成状态创建 ChartDataPoint
  const ChartDataPoint({
    required this.date,
    required this.value,
    required this.isCompleted,
  });
}

/// Time range for charts
/// 图表的时间范围
enum TimeRange {
  week, // 7 days
  month, // 30 days
  quarter, // 90 days
  all, // All time
}

extension TimeRangeExtension on TimeRange {
  /// Get display name for the time range
  /// 获取时间范围的显示名称
  String get displayName {
    switch (this) {
      case TimeRange.week:
        return '7D';
      case TimeRange.month:
        return '30D';
      case TimeRange.quarter:
        return '90D';
      case TimeRange.all:
        return 'All';
    }
  }

  /// Get number of days for the time range
  /// 获取时间范围对应的天数
  int? get days {
    switch (this) {
      case TimeRange.week:
        return 7;
      case TimeRange.month:
        return 30;
      case TimeRange.quarter:
        return 90;
      case TimeRange.all:
        return null; // All time
    }
  }
}
