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
enum SubscriptionTier {
  starter,
  growth,
  mastery,
}

/// Extension methods for SubscriptionTier
extension SubscriptionTierExtension on SubscriptionTier {
  /// Display name for the tier
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
  bool get hasFullAnalytics {
    return this == SubscriptionTier.mastery;
  }

  /// Whether achievements are available
  bool get hasAchievements {
    return this == SubscriptionTier.mastery;
  }

  /// Maximum AI reports per month (insights, scores, reviews, etc.)
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
class SubscriptionLimits {
  final SubscriptionTier tier;
  final int currentHabitCount;
  final int aiSuggestionsUsedToday;
  final DateTime? lastSuggestionDate;
  final int aiReportsUsedThisMonth;
  final DateTime? lastReportDate;

  const SubscriptionLimits({
    this.tier = SubscriptionTier.starter,
    this.currentHabitCount = 0,
    this.aiSuggestionsUsedToday = 0,
    this.lastSuggestionDate,
    this.aiReportsUsedThisMonth = 0,
    this.lastReportDate,
  });

  /// Check if user can add more habits
  bool get canAddHabit {
    final max = tier.maxHabits;
    if (max == -1) return true; // Unlimited
    return currentHabitCount < max;
  }

  /// Get remaining habits that can be added
  int get remainingHabits {
    final max = tier.maxHabits;
    if (max == -1) return 999; // Effectively unlimited
    return (max - currentHabitCount).clamp(0, max);
  }

  /// Check if user can use AI suggestions today
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
