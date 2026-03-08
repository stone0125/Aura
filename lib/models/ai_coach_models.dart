// =============================================================================
// ai_coach_models.dart — AI Coach Data Models
// AI 教练数据模型
//
// Data classes for AI coach features: suggestions with impact/effort ratings,
// weekly summaries, detected behaviour patterns, tips, and action items.
// Used by AICoachProvider to display AI-generated content on the coach screen.
//
// AI 教练功能的数据类：带有影响/努力评级的建议、每周总结、
// 检测到的行为模式、技巧和行动项。
// 由 AICoachProvider 使用，在教练界面显示 AI 生成的内容。
// =============================================================================

import 'package:flutter/material.dart';
import 'habit_category.dart';

/// AI-generated habit suggestion for the coach screen
/// AI 生成的教练界面习惯建议
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
  final String frequencyType; // "daily" or "weekly"
  final List<int>? weeklyDays; // [0-6] if weekly, null if daily
  final String goalType; // "none", "time", or "count"
  final int? goalValue; // numeric target, null if none
  final String? goalUnit; // e.g. "minutes", "pages", null if none
  final int? suggestedReminderHour; // 0-23, null if no recommendation
  final int? suggestedReminderMinute; // 0-59

  /// Creates an AICoachSuggestion with all required and optional fields
  /// 使用所有必需和可选字段创建 AICoachSuggestion
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
    this.frequencyType = 'daily',
    this.weeklyDays,
    this.goalType = 'none',
    this.goalValue,
    this.goalUnit,
    this.suggestedReminderHour,
    this.suggestedReminderMinute,
  });

  /// Serialize this suggestion to a JSON map
  /// 将此建议序列化为 JSON 映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'whyThisHelps': whyThisHelps,
      'category': category.name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'estimatedImpact': estimatedImpact,
      'estimatedMinutes': estimatedMinutes,
      'suggestedAt': suggestedAt.toIso8601String(),
      'frequencyType': frequencyType,
      'weeklyDays': weeklyDays,
      'goalType': goalType,
      'goalValue': goalValue,
      'goalUnit': goalUnit,
      'suggestedReminderHour': suggestedReminderHour,
      'suggestedReminderMinute': suggestedReminderMinute,
    };
  }

  /// Create an AICoachSuggestion from a JSON map with safe parsing
  /// 从 JSON 映射创建 AICoachSuggestion，带有安全解析
  factory AICoachSuggestion.fromJson(Map<String, dynamic> json) {
    // Restore icon if serialized, otherwise use default
    IconData restoredIcon = Icons.lightbulb_outline;
    if (json['iconCodePoint'] != null) {
      restoredIcon = IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
      );
    }

    // Safe category parsing with type check
    HabitCategory category = HabitCategory.health;
    final categoryValue = json['category'];
    if (categoryValue is String) {
      category = HabitCategory.values.firstWhere(
        (e) => e.name == categoryValue,
        orElse: () => HabitCategory.health,
      );
    }

    return AICoachSuggestion(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Untitled',
      description: json['description']?.toString() ?? '',
      whyThisHelps: json['whyThisHelps']?.toString() ?? '',
      category: category,
      icon: restoredIcon,
      estimatedImpact: json['estimatedImpact']?.toString() ?? 'Medium',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 15,
      suggestedAt: json['suggestedAt'] != null
          ? DateTime.tryParse(json['suggestedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      frequencyType: json['frequencyType']?.toString() ?? 'daily',
      weeklyDays: json['weeklyDays'] is List
          ? List<int>.from((json['weeklyDays'] as List).map((e) => (e as num?)?.toInt() ?? 0))
          : null,
      goalType: json['goalType']?.toString() ?? 'none',
      goalValue: (json['goalValue'] as num?)?.toInt(),
      goalUnit: json['goalUnit']?.toString(),
      suggestedReminderHour: (json['suggestedReminderHour'] as num?)?.toInt(),
      suggestedReminderMinute: (json['suggestedReminderMinute'] as num?)?.toInt(),
    );
  }

  /// Get impact color based on level
  /// 根据影响级别获取颜色
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

/// A structured next-step from AI weekly insights
/// AI 每周洞察中的结构化下一步操作
class AINextStep {
  final String action;
  final String timeframe; // "today", "this week", etc.
  final String priority; // "high", "medium", "low"

  /// Creates an AINextStep with action, timeframe, and priority
  /// 使用操作、时间范围和优先级创建 AINextStep
  const AINextStep({
    required this.action,
    required this.timeframe,
    required this.priority,
  });

  /// Serialize this next step to a JSON map
  /// 将此下一步操作序列化为 JSON 映射
  Map<String, dynamic> toJson() => {
    'action': action,
    'timeframe': timeframe,
    'priority': priority,
  };

  /// Create an AINextStep from a JSON map
  /// 从 JSON 映射创建 AINextStep
  factory AINextStep.fromJson(Map<String, dynamic> json) {
    return AINextStep(
      action: json['action']?.toString() ?? '',
      timeframe: json['timeframe']?.toString() ?? 'this week',
      priority: json['priority']?.toString() ?? 'medium',
    );
  }

  /// Get color based on priority level
  /// 根据优先级获取颜色
  Color getPriorityColor(bool isDark) {
    switch (priority.toLowerCase()) {
      case 'high':
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFF44336);
      case 'low':
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF2196F3);
      default:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
    }
  }
}

/// Weekly AI summary
/// 每周 AI 总结
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
  final List<String> completionSnapshot; // Sorted habit IDs completed at generation time
  final List<AINextStep> nextSteps; // Structured next-steps from AI

  /// Creates a WeeklyAISummary with performance data and AI commentary
  /// 使用表现数据和 AI 评语创建 WeeklyAISummary
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
    this.completionSnapshot = const [],
    this.nextSteps = const [],
  });

  /// Serialize this weekly summary to a JSON map
  /// 将此每周总结序列化为 JSON 映射
  Map<String, dynamic> toJson() {
    return {
      'weekRange': weekRange,
      'totalCompletions': totalCompletions,
      'targetCompletions': targetCompletions,
      'completionRate': completionRate,
      'currentStreak': currentStreak,
      'topCategory': topCategory,
      'insight': insight,
      'encouragement': encouragement,
      'highlights': highlights,
      'completionSnapshot': completionSnapshot,
      'nextSteps': nextSteps.map((s) => s.toJson()).toList(),
    };
  }

  /// Create a WeeklyAISummary from a JSON map
  /// 从 JSON 映射创建 WeeklyAISummary
  factory WeeklyAISummary.fromJson(Map<String, dynamic> json) {
    return WeeklyAISummary(
      weekRange: json['weekRange']?.toString() ?? '',
      totalCompletions: (json['totalCompletions'] as num?)?.toInt() ?? 0,
      targetCompletions: (json['targetCompletions'] as num?)?.toInt() ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      topCategory: json['topCategory']?.toString() ?? '',
      insight: json['insight']?.toString() ?? '',
      encouragement: json['encouragement']?.toString() ?? '',
      highlights: json['highlights'] is List
          ? List<String>.from((json['highlights'] as List).map((e) => e?.toString() ?? ''))
          : const [],
      completionSnapshot: json['completionSnapshot'] is List
          ? List<String>.from((json['completionSnapshot'] as List).map((e) => e?.toString() ?? ''))
          : const [],
      nextSteps: json['nextSteps'] is List
          ? (json['nextSteps'] as List)
              .whereType<Map>()
              .map((e) => AINextStep.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  /// Get performance level
  /// 获取表现等级
  String get performanceLevel {
    if (completionRate >= 0.9) return 'Excellent';
    if (completionRate >= 0.7) return 'Good';
    if (completionRate >= 0.5) return 'Fair';
    return 'Needs Improvement';
  }

  /// Get performance color
  /// 获取表现对应的颜色
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
/// AI 发现的行为模式
class AIPattern {
  final String id;
  final String title;
  final String description;
  final PatternType type;
  final String insight;
  final IconData icon;
  final double confidence; // 0.0 to 1.0
  final DateTime discoveredAt;

  /// Creates an AIPattern with all required properties
  /// 使用所有必需属性创建 AIPattern
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

  /// Icon name string to IconData lookup
  /// 图标名称字符串到 IconData 的查找映射
  static const Map<String, IconData> _iconMap = {
    'schedule': Icons.schedule,
    'wb_sunny': Icons.wb_sunny,
    'nightlight': Icons.nightlight_round,
    'calendar_today': Icons.calendar_today,
    'weekend': Icons.weekend,
    'link': Icons.link,
    'repeat': Icons.repeat,
    'bolt': Icons.bolt,
    'insights': Icons.insights,
  };

  /// Reverse lookup: IconData to string name
  /// 反向查找：IconData 到字符串名称
  static String _iconToString(IconData icon) {
    for (final entry in _iconMap.entries) {
      if (entry.value.codePoint == icon.codePoint) return entry.key;
    }
    return 'insights';
  }

  /// Serialize this pattern to a JSON map
  /// 将此模式序列化为 JSON 映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'insight': insight,
      'iconName': _iconToString(icon),
      'confidence': confidence,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }

  /// Create an AIPattern from a JSON map with safe parsing
  /// 从 JSON 映射创建 AIPattern，带有安全解析
  factory AIPattern.fromJson(Map<String, dynamic> json) {
    // Parse PatternType with fallback
    PatternType type = PatternType.timeOfDay;
    final typeStr = json['type']?.toString();
    if (typeStr != null) {
      type = PatternType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => PatternType.timeOfDay,
      );
    }

    // Parse icon from string name with fallback
    final iconName = json['iconName']?.toString() ?? 'insights';
    final icon = _iconMap[iconName] ?? Icons.insights;

    return AIPattern(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Pattern',
      description: json['description']?.toString() ?? '',
      type: type,
      insight: json['insight']?.toString() ?? '',
      icon: icon,
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.5)
          .clamp(0.0, 1.0),
      discoveredAt: json['discoveredAt'] != null
          ? DateTime.tryParse(json['discoveredAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Get confidence label
  /// 获取置信度标签
  String get confidenceLabel {
    if (confidence >= 0.8) return 'High confidence';
    if (confidence >= 0.6) return 'Medium confidence';
    return 'Low confidence';
  }

  /// Get pattern color based on type
  /// 根据模式类型获取颜色
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
/// 发现的模式类型
enum PatternType {
  timeOfDay, // e.g., "You complete habits better in the morning"
  dayOfWeek, // e.g., "You're most consistent on weekdays"
  sequence, // e.g., "Meditation helps you complete other habits"
  trigger, // e.g., "You complete habits after breakfast"
}

extension PatternTypeExtension on PatternType {
  /// Get display name for the pattern type
  /// 获取模式类型的显示名称
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
/// 用于建立习惯的 AI 技巧
class AITip {
  final String id;
  final String title;
  final String content;
  final TipCategory category;
  final List<String> keyPoints;
  final String? actionable; // Optional actionable step
  final IconData icon;
  final bool isBookmarked;

  /// Creates an AITip with all required and optional fields
  /// 使用所有必需和可选字段创建 AITip
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

  /// Serialize this tip to a JSON map
  /// 将此技巧序列化为 JSON 映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category.name,
      'keyPoints': keyPoints,
      'actionable': actionable,
      'isBookmarked': isBookmarked,
    };
  }

  /// Create an AITip from a JSON map with safe parsing
  /// 从 JSON 映射创建 AITip，带有安全解析
  factory AITip.fromJson(Map<String, dynamic> json) {
    // Safe category parsing with type check
    TipCategory category = TipCategory.gettingStarted;
    final categoryValue = json['category'];
    if (categoryValue is String) {
      category = TipCategory.values.firstWhere(
        (e) => e.name == categoryValue,
        orElse: () => TipCategory.gettingStarted,
      );
    }

    // Safe keyPoints parsing
    List<String> keyPoints = [];
    if (json['keyPoints'] is List) {
      keyPoints = (json['keyPoints'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return AITip(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Untitled',
      content: json['content']?.toString() ?? '',
      category: category,
      keyPoints: keyPoints,
      actionable: json['actionable']?.toString(),
      icon: category.icon, // Re-derive icon from category
      isBookmarked: json['isBookmarked'] == true,
    );
  }

  /// Create a copy with optionally updated bookmark status
  /// 创建一个可选更新书签状态的副本
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
/// 技巧类别
enum TipCategory {
  gettingStarted,
  stayingConsistent,
  overcomingChallenges,
  advancedStrategies,
  mindsetAndMotivation,
}

extension TipCategoryExtension on TipCategory {
  /// Get display name for the tip category
  /// 获取技巧类别的显示名称
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

  /// Get icon for the tip category
  /// 获取技巧类别的图标
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

  /// Get color for the tip category based on theme
  /// 根据主题获取技巧类别的颜色
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
/// AI 教练标签页枚举
enum AICoachTab { suggestions, insights, scores, actions }

extension AICoachTabExtension on AICoachTab {
  /// Get display name for the AI coach tab
  /// 获取 AI 教练标签页的显示名称
  String get displayName {
    switch (this) {
      case AICoachTab.suggestions:
        return 'Suggestions';
      case AICoachTab.insights:
        return 'Insights';
      case AICoachTab.scores:
        return 'Scores';
      case AICoachTab.actions:
        return 'Actions';
    }
  }

  /// Get icon for the AI coach tab
  /// 获取 AI 教练标签页的图标
  IconData get icon {
    switch (this) {
      case AICoachTab.suggestions:
        return Icons.lightbulb_outline_rounded;
      case AICoachTab.insights:
        return Icons.insights_rounded;
      case AICoachTab.scores:
        return Icons.speed_rounded;
      case AICoachTab.actions:
        return Icons.checklist_rounded;
    }
  }
}

/// Type of action item
/// 行动项类型
enum ActionItemType { daily, weekly, challenge }

extension ActionItemTypeExtension on ActionItemType {
  /// Get display name for the action item type
  /// 获取行动项类型的显示名称
  String get displayName {
    switch (this) {
      case ActionItemType.daily:
        return 'Today';
      case ActionItemType.weekly:
        return 'This Week';
      case ActionItemType.challenge:
        return 'Challenge';
    }
  }
}

/// Priority level for action items
/// 行动项的优先级
enum ActionPriority { high, medium, low }

extension ActionPriorityExtension on ActionPriority {
  /// Get display name for the priority level
  /// 获取优先级的显示名称
  String get displayName {
    switch (this) {
      case ActionPriority.high:
        return 'High';
      case ActionPriority.medium:
        return 'Medium';
      case ActionPriority.low:
        return 'Low';
    }
  }

  /// Get color for the priority level based on theme
  /// 根据主题获取优先级的颜色
  Color getColor(bool isDark) {
    switch (this) {
      case ActionPriority.high:
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFF44336);
      case ActionPriority.medium:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
      case ActionPriority.low:
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF2196F3);
    }
  }
}

/// AI-generated personalized action item
/// AI 生成的个性化行动项
class AIActionItem {
  final String id;
  final String title;
  final String description;
  final ActionItemType type;
  final ActionPriority priority;
  final String? relatedHabit;
  final String? relatedHabitId;
  final String? metric;
  final bool isCompleted;
  final DateTime createdAt;

  /// Creates an AIActionItem with all required and optional fields
  /// 使用所有必需和可选字段创建 AIActionItem
  const AIActionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.relatedHabit,
    this.relatedHabitId,
    this.metric,
    this.isCompleted = false,
    required this.createdAt,
  });

  /// Serialize this action item to a JSON map
  /// 将此行动项序列化为 JSON 映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'relatedHabit': relatedHabit,
      'relatedHabitId': relatedHabitId,
      'metric': metric,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create an AIActionItem from a JSON map with safe parsing
  /// 从 JSON 映射创建 AIActionItem，带有安全解析
  factory AIActionItem.fromJson(Map<String, dynamic> json) {
    ActionItemType type = ActionItemType.daily;
    final typeStr = json['type']?.toString();
    if (typeStr != null) {
      type = ActionItemType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => ActionItemType.daily,
      );
    }

    ActionPriority priority = ActionPriority.medium;
    final priorityStr = json['priority']?.toString();
    if (priorityStr != null) {
      priority = ActionPriority.values.firstWhere(
        (e) => e.name == priorityStr,
        orElse: () => ActionPriority.medium,
      );
    }

    return AIActionItem(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Action Item',
      description: json['description']?.toString() ?? '',
      type: type,
      priority: priority,
      relatedHabit: json['relatedHabit']?.toString(),
      relatedHabitId: json['relatedHabitId']?.toString(),
      metric: json['metric']?.toString(),
      isCompleted: json['isCompleted'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Create a copy with optionally updated completion status
  /// 创建一个可选更新完成状态的副本
  AIActionItem copyWith({bool? isCompleted}) {
    return AIActionItem(
      id: id,
      title: title,
      description: description,
      type: type,
      priority: priority,
      relatedHabit: relatedHabit,
      relatedHabitId: relatedHabitId,
      metric: metric,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
