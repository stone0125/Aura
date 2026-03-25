// =============================================================================
// NOTE: This file is for future work and is not included in the dissertation report.
// =============================================================================
// subscription_models.dart — Subscription & Tier Models
// 订阅与层级模型
//
// Models for RevenueCat subscription management. Defines three tiers:
// Starter (free), Growth, and Mastery — each with different limits on
// habits, AI features, and export capabilities. Contains SubscriptionTier
// enum, TierLimits, and UsageInfo for quota tracking.
//
// RevenueCat 订阅管理的数据模型。定义三个层级：
// Starter（免费）、Growth 和 Mastery——每个层级对习惯数量、
// AI 功能和导出能力有不同限制。包含 SubscriptionTier 枚举、
// TierLimits 和 UsageInfo（配额追踪）。
// =============================================================================

/// Subscription tier enumeration
/// 订阅层级枚举
enum SubscriptionTier {
  starter,
  growth,
  mastery,
}

/// Extension methods for SubscriptionTier
/// SubscriptionTier 的扩展方法
extension SubscriptionTierExtension on SubscriptionTier {
  /// Display name for the tier
  /// 层级的显示名称
  String get displayName {
    switch (this) {
      case SubscriptionTier.starter:
        return 'Starter';
      case SubscriptionTier.growth:
        return 'Growth';
      case SubscriptionTier.mastery:
        return 'Mastery';
    }
  }

  /// Maximum number of habits allowed
  /// 允许的最大习惯数量
  int get maxHabits {
    switch (this) {
      case SubscriptionTier.starter:
        return 5;
      case SubscriptionTier.growth:
        return 10;
      case SubscriptionTier.mastery:
        return -1; // Unlimited
    }
  }

  /// Maximum AI suggestions per day
  /// 每日最大 AI 建议数量
  int get maxAISuggestionsPerDay {
    switch (this) {
      case SubscriptionTier.starter:
        return 3;
      case SubscriptionTier.growth:
        return 5;
      case SubscriptionTier.mastery:
        return -1; // Unlimited
    }
  }

  /// Whether trend charts are available
  /// 趋势图表是否可用
  bool get hasTrendCharts {
    switch (this) {
      case SubscriptionTier.starter:
        return false;
      case SubscriptionTier.growth:
      case SubscriptionTier.mastery:
        return true;
    }
  }

  /// Whether full analytics are available
  /// 完整分析功能是否可用
  bool get hasFullAnalytics {
    return this == SubscriptionTier.mastery;
  }

  /// Whether achievements are available
  /// 成就功能是否可用
  bool get hasAchievements {
    return this == SubscriptionTier.mastery;
  }

  /// Maximum AI reports per month (insights, scores, reviews, etc.)
  /// 每月最大 AI 报告数量（洞察、评分、回顾等）
  int get maxAIReportsPerMonth {
    switch (this) {
      case SubscriptionTier.starter:
        return 20;
      case SubscriptionTier.growth:
        return 30;
      case SubscriptionTier.mastery:
        return -1; // Unlimited
    }
  }

  /// Description of what's included
  /// 包含内容的描述
  String get description {
    switch (this) {
      case SubscriptionTier.starter:
        return 'Basic habit tracking with up to 5 habits';
      case SubscriptionTier.growth:
        return 'Enhanced tracking with 10 habits and trend charts';
      case SubscriptionTier.mastery:
        return 'Unlimited habits with full analytics and achievements';
    }
  }
}

/// Subscription limits and current usage tracking
/// 订阅限制与当前使用量追踪
class SubscriptionLimits {
  final SubscriptionTier tier;
  final int currentHabitCount;
  final int aiSuggestionsUsedToday;
  final DateTime? lastSuggestionDate;
  final int aiReportsUsedThisMonth;
  final DateTime? lastReportDate;

  /// Creates SubscriptionLimits with default Starter tier values
  /// 使用默认 Starter 层级值创建 SubscriptionLimits
  const SubscriptionLimits({
    this.tier = SubscriptionTier.starter,
    this.currentHabitCount = 0,
    this.aiSuggestionsUsedToday = 0,
    this.lastSuggestionDate,
    this.aiReportsUsedThisMonth = 0,
    this.lastReportDate,
  });

  /// Check if user can add more habits
  /// 检查用户是否可以添加更多习惯
  bool get canAddHabit {
    final max = tier.maxHabits;
    if (max == -1) return true; // Unlimited
    return currentHabitCount < max;
  }

  /// Get remaining habits that can be added
  /// 获取可添加的剩余习惯数量
  int get remainingHabits {
    final max = tier.maxHabits;
    if (max == -1) return 999; // Effectively unlimited
    return (max - currentHabitCount).clamp(0, max);
  }

  /// Check if user can use AI suggestions today
  /// 检查用户今天是否可以使用 AI 建议
  bool get canUseAISuggestion {
    final max = tier.maxAISuggestionsPerDay;
    if (max == -1) return true; // Unlimited

    // Check if it's a new day
    if (lastSuggestionDate != null) {
      final now = DateTime.now();
      final isSameDay =
          lastSuggestionDate!.year == now.year &&
          lastSuggestionDate!.month == now.month &&
          lastSuggestionDate!.day == now.day;
      if (!isSameDay) return true; // New day, reset
    }

    return aiSuggestionsUsedToday < max;
  }

  /// Get remaining AI suggestions for today
  /// 获取今天剩余的 AI 建议次数
  int get remainingAISuggestions {
    final max = tier.maxAISuggestionsPerDay;
    if (max == -1) return 999; // Effectively unlimited

    // Check if it's a new day
    if (lastSuggestionDate != null) {
      final now = DateTime.now();
      final isSameDay =
          lastSuggestionDate!.year == now.year &&
          lastSuggestionDate!.month == now.month &&
          lastSuggestionDate!.day == now.day;
      if (!isSameDay) return max; // New day, reset
    } else {
      return max; // Never used
    }

    return (max - aiSuggestionsUsedToday).clamp(0, max);
  }

  /// Check if user can use AI reports this month
  /// 检查用户本月是否可以使用 AI 报告
  bool get canUseAIReport {
    final max = tier.maxAIReportsPerMonth;
    if (max == -1) return true; // Unlimited

    // Check if it's a new month
    if (lastReportDate != null) {
      final now = DateTime.now();
      final isSameMonth =
          lastReportDate!.year == now.year &&
          lastReportDate!.month == now.month;
      if (!isSameMonth) return true; // New month, reset
    }

    return aiReportsUsedThisMonth < max;
  }

  /// Get remaining AI reports for this month
  /// 获取本月剩余的 AI 报告次数
  int get remainingAIReports {
    final max = tier.maxAIReportsPerMonth;
    if (max == -1) return 999; // Effectively unlimited

    // Check if it's a new month
    if (lastReportDate != null) {
      final now = DateTime.now();
      final isSameMonth =
          lastReportDate!.year == now.year &&
          lastReportDate!.month == now.month;
      if (!isSameMonth) return max; // New month, reset
    } else {
      return max; // Never used
    }

    return (max - aiReportsUsedThisMonth).clamp(0, max);
  }

  /// Create a copy with updated values
  /// 创建一个更新了指定值的副本
  SubscriptionLimits copyWith({
    SubscriptionTier? tier,
    int? currentHabitCount,
    int? aiSuggestionsUsedToday,
    DateTime? lastSuggestionDate,
    int? aiReportsUsedThisMonth,
    DateTime? lastReportDate,
  }) {
    return SubscriptionLimits(
      tier: tier ?? this.tier,
      currentHabitCount: currentHabitCount ?? this.currentHabitCount,
      aiSuggestionsUsedToday:
          aiSuggestionsUsedToday ?? this.aiSuggestionsUsedToday,
      lastSuggestionDate: lastSuggestionDate ?? this.lastSuggestionDate,
      aiReportsUsedThisMonth:
          aiReportsUsedThisMonth ?? this.aiReportsUsedThisMonth,
      lastReportDate: lastReportDate ?? this.lastReportDate,
    );
  }
}
