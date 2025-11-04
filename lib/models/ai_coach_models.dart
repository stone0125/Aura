import 'package:flutter/material.dart';
import 'habit_category.dart';

/// AI-generated habit suggestion for the coach screen
class AICoachSuggestion {
  final String id;
  final String title;
  final String description;
  final String whyThisHelps;
  final HabitCategory category;
  final IconData icon;
  final String estimatedImpact; // e.g., "High", "Medium", "Low"
  final int estimatedMinutes; // Time commitment
  final DateTime suggestedAt;

  const AICoachSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.whyThisHelps,
    required this.category,
    required this.icon,
    required this.estimatedImpact,
    required this.estimatedMinutes,
    required this.suggestedAt,
  });

  /// Get impact color based on level
  Color getImpactColor(bool isDark) {
    switch (estimatedImpact.toLowerCase()) {
      case 'high':
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);
      case 'medium':
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
      case 'low':
        return isDark ? const Color(0xFF90CAF9) : const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }
}

/// Weekly AI summary
class WeeklyAISummary {
  final String weekRange; // e.g., "Oct 28 - Nov 3"
  final int totalCompletions;
  final int targetCompletions;
  final double completionRate;
  final int currentStreak;
  final String topCategory;
  final String insight;
  final String encouragement;
  final List<String> highlights; // Bullet points

  const WeeklyAISummary({
    required this.weekRange,
    required this.totalCompletions,
    required this.targetCompletions,
    required this.completionRate,
    required this.currentStreak,
    required this.topCategory,
    required this.insight,
    required this.encouragement,
    required this.highlights,
  });

  /// Get week performance level
  String get performanceLevel {
    if (completionRate >= 0.9) return 'Excellent';
    if (completionRate >= 0.7) return 'Good';
    if (completionRate >= 0.5) return 'Fair';
    return 'Needs Improvement';
  }

  /// Get performance color
  Color getPerformanceColor(bool isDark) {
    if (completionRate >= 0.9) {
      return isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);
    }
    if (completionRate >= 0.7) {
      return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
    }
    return isDark ? const Color(0xFFEF5350) : const Color(0xFFF44336);
  }
}

/// Pattern discovered by AI
class AIPattern {
  final String id;
  final String title;
  final String description;
  final PatternType type;
  final String insight;
  final IconData icon;
  final double confidence; // 0.0 to 1.0
  final DateTime discoveredAt;

  const AIPattern({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.insight,
    required this.icon,
    required this.confidence,
    required this.discoveredAt,
  });

  /// Get confidence label
  String get confidenceLabel {
    if (confidence >= 0.8) return 'High confidence';
    if (confidence >= 0.6) return 'Medium confidence';
    return 'Low confidence';
  }

  /// Get pattern color based on type
  Color getPatternColor(bool isDark) {
    switch (type) {
      case PatternType.timeOfDay:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
      case PatternType.dayOfWeek:
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF2196F3);
      case PatternType.sequence:
        return isDark ? const Color(0xFF9575CD) : const Color(0xFF673AB7);
      case PatternType.trigger:
        return isDark ? const Color(0xFF4DB6AC) : const Color(0xFF009688);
    }
  }
}

/// Type of pattern discovered
enum PatternType {
  timeOfDay, // e.g., "You complete habits better in the morning"
  dayOfWeek, // e.g., "You're most consistent on weekdays"
  sequence, // e.g., "Meditation helps you complete other habits"
  trigger, // e.g., "You complete habits after breakfast"
}

extension PatternTypeExtension on PatternType {
  String get displayName {
    switch (this) {
      case PatternType.timeOfDay:
        return 'Time Pattern';
      case PatternType.dayOfWeek:
        return 'Day Pattern';
      case PatternType.sequence:
        return 'Habit Sequence';
      case PatternType.trigger:
        return 'Trigger Pattern';
    }
  }
}

/// AI tip for habit building
class AITip {
  final String id;
  final String title;
  final String content;
  final TipCategory category;
  final List<String> keyPoints;
  final String? actionable; // Optional actionable step
  final IconData icon;
  final bool isBookmarked;

  const AITip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.keyPoints,
    this.actionable,
    required this.icon,
    this.isBookmarked = false,
  });

  AITip copyWith({bool? isBookmarked}) {
    return AITip(
      id: id,
      title: title,
      content: content,
      category: category,
      keyPoints: keyPoints,
      actionable: actionable,
      icon: icon,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

/// Tip category
enum TipCategory {
  gettingStarted,
  stayingConsistent,
  overcomingChallenges,
  advancedStrategies,
  mindsetAndMotivation,
}

extension TipCategoryExtension on TipCategory {
  String get displayName {
    switch (this) {
      case TipCategory.gettingStarted:
        return 'Getting Started';
      case TipCategory.stayingConsistent:
        return 'Staying Consistent';
      case TipCategory.overcomingChallenges:
        return 'Overcoming Challenges';
      case TipCategory.advancedStrategies:
        return 'Advanced Strategies';
      case TipCategory.mindsetAndMotivation:
        return 'Mindset & Motivation';
    }
  }

  IconData get icon {
    switch (this) {
      case TipCategory.gettingStarted:
        return Icons.play_circle_outline_rounded;
      case TipCategory.stayingConsistent:
        return Icons.repeat_rounded;
      case TipCategory.overcomingChallenges:
        return Icons.shield_outlined;
      case TipCategory.advancedStrategies:
        return Icons.trending_up_rounded;
      case TipCategory.mindsetAndMotivation:
        return Icons.psychology_outlined;
    }
  }

  Color getColor(bool isDark) {
    switch (this) {
      case TipCategory.gettingStarted:
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);
      case TipCategory.stayingConsistent:
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF2196F3);
      case TipCategory.overcomingChallenges:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
      case TipCategory.advancedStrategies:
        return isDark ? const Color(0xFF9575CD) : const Color(0xFF673AB7);
      case TipCategory.mindsetAndMotivation:
        return isDark ? const Color(0xFFFF8A80) : const Color(0xFFFF6B6B);
    }
  }
}

/// AI Coach tab enum
enum AICoachTab {
  suggestions,
  insights,
  tips,
}

extension AICoachTabExtension on AICoachTab {
  String get displayName {
    switch (this) {
      case AICoachTab.suggestions:
        return 'Suggestions';
      case AICoachTab.insights:
        return 'Insights';
      case AICoachTab.tips:
        return 'Tips';
    }
  }
}
