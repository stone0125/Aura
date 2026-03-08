// =============================================================================
// ai_scoring_models.dart — AI Scoring Data Models
// AI 评分数据模型
//
// Models for the AI habit scoring system. Each habit is scored across
// 4 dimensions (0-100): Consistency, Momentum, Resilience, Engagement.
// Contains ScoreComponent (individual dimension) and HabitScore (aggregate).
//
// AI 习惯评分系统的数据模型。每个习惯在 4 个维度（0-100）上评分：
// 一致性、动力、韧性、参与度。
// 包含 ScoreComponent（单个维度）和 HabitScore（综合评分）。
// =============================================================================

/// Individual score component for a dimension of habit performance
/// 习惯表现某一维度的单个评分组件
class ScoreComponent {
  final int score;
  final String analysis;

  /// Creates a ScoreComponent with score value and analysis text
  /// 使用分数值和分析文本创建 ScoreComponent
  const ScoreComponent({
    required this.score,
    required this.analysis,
  });

  /// Create a ScoreComponent from a JSON map
  /// 从 JSON 映射创建 ScoreComponent
  factory ScoreComponent.fromJson(Map<String, dynamic> json) {
    return ScoreComponent(
      score: (json['score'] as num?)?.toInt() ?? 0,
      analysis: json['analysis']?.toString() ?? '',
    );
  }

  /// Serialize this score component to a JSON map
  /// 将此评分组件序列化为 JSON 映射
  Map<String, dynamic> toJson() => {
        'score': score,
        'analysis': analysis,
      };
}

/// Breakdown of habit score across multiple dimensions
/// 习惯评分的多维度分解
class ScoreBreakdown {
  final ScoreComponent consistency;
  final ScoreComponent momentum;
  final ScoreComponent resilience;
  final ScoreComponent engagement;

  /// Creates a ScoreBreakdown with all four dimension scores
  /// 使用所有四个维度的分数创建 ScoreBreakdown
  const ScoreBreakdown({
    required this.consistency,
    required this.momentum,
    required this.resilience,
    required this.engagement,
  });

  /// Create a ScoreBreakdown from a JSON map
  /// 从 JSON 映射创建 ScoreBreakdown
  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      consistency: ScoreComponent.fromJson(
          json['consistency'] is Map ? Map<String, dynamic>.from(json['consistency']) : {}),
      momentum: ScoreComponent.fromJson(
          json['momentum'] is Map ? Map<String, dynamic>.from(json['momentum']) : {}),
      resilience: ScoreComponent.fromJson(
          json['resilience'] is Map ? Map<String, dynamic>.from(json['resilience']) : {}),
      engagement: ScoreComponent.fromJson(
          json['engagement'] is Map ? Map<String, dynamic>.from(json['engagement']) : {}),
    );
  }

  /// Serialize this breakdown to a JSON map
  /// 将此分解序列化为 JSON 映射
  Map<String, dynamic> toJson() => {
        'consistency': consistency.toJson(),
        'momentum': momentum.toJson(),
        'resilience': resilience.toJson(),
        'engagement': engagement.toJson(),
      };

  /// Get average score across all components
  /// 获取所有组件的平均分
  double get averageScore =>
      (consistency.score + momentum.score + resilience.score + engagement.score) /
      4;
}

/// Comprehensive habit score from AI analysis
/// AI 分析的综合习惯评分
class HabitScore {
  final String habitId;
  final int overallScore;
  final String grade;
  final ScoreBreakdown breakdown;
  final String primaryStrength;
  final String primaryWeakness;
  final String recommendation;
  final String comparisonToAverage;
  final String? healthCorrelation;
  final DateTime generatedAt;

  /// Creates a HabitScore with all required and optional fields
  /// 使用所有必需和可选字段创建 HabitScore
  const HabitScore({
    required this.habitId,
    required this.overallScore,
    required this.grade,
    required this.breakdown,
    required this.primaryStrength,
    required this.primaryWeakness,
    required this.recommendation,
    required this.comparisonToAverage,
    this.healthCorrelation,
    required this.generatedAt,
  });

  /// Create a HabitScore from a JSON map with optional habitId override
  /// 从 JSON 映射创建 HabitScore，可选覆盖 habitId
  factory HabitScore.fromJson(Map<String, dynamic> json, {String? habitId}) {
    return HabitScore(
      habitId: habitId ?? json['habitId']?.toString() ?? '',
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
      grade: json['grade']?.toString() ?? 'N/A',
      breakdown:
          ScoreBreakdown.fromJson(json['breakdown'] is Map ? Map<String, dynamic>.from(json['breakdown']) : {}),
      primaryStrength: json['primaryStrength']?.toString() ?? '',
      primaryWeakness: json['primaryWeakness']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
      comparisonToAverage: json['comparisonToAverage']?.toString() ?? '',
      healthCorrelation: json['healthCorrelation']?.toString(),
      generatedAt: json['generatedAt'] != null
          ? (DateTime.tryParse(json['generatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  /// Serialize this habit score to a JSON map
  /// 将此习惯评分序列化为 JSON 映射
  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'overallScore': overallScore,
        'grade': grade,
        'breakdown': breakdown.toJson(),
        'primaryStrength': primaryStrength,
        'primaryWeakness': primaryWeakness,
        'recommendation': recommendation,
        'comparisonToAverage': comparisonToAverage,
        'healthCorrelation': healthCorrelation,
        'generatedAt': generatedAt.toIso8601String(),
      };

  /// Check if grade is Excellent (A)
  /// 检查成绩是否为优秀（A）
  bool get isExcellent => grade.startsWith('A');
  /// Check if grade is Good (B)
  /// 检查成绩是否为良好（B）
  bool get isGood => grade.startsWith('B');
  /// Check if grade is Average (C)
  /// 检查成绩是否为一般（C）
  bool get isAverage => grade.startsWith('C');
  /// Check if grade needs improvement (D or F)
  /// 检查成绩是否需要改进（D 或 F）
  bool get needsImprovement => grade.startsWith('D') || grade.startsWith('F');

  /// Get score tier description
  /// 获取分数等级描述
  String get scoreTier {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Great';
    if (overallScore >= 70) return 'Good';
    if (overallScore >= 60) return 'Fair';
    return 'Needs Work';
  }

  /// Calculate score change from previous
  /// 计算与之前评分的变化量
  int scoreChange(HabitScore? previous) {
    if (previous == null) return 0;
    return overallScore - previous.overallScore;
  }
}

/// Historical score entry for tracking progress over time
/// 用于跟踪进度的历史评分条目
class ScoreHistoryEntry {
  final DateTime date;
  final int score;
  final String grade;

  /// Creates a ScoreHistoryEntry with date, score, and grade
  /// 使用日期、分数和等级创建 ScoreHistoryEntry
  const ScoreHistoryEntry({
    required this.date,
    required this.score,
    required this.grade,
  });

  /// Create a ScoreHistoryEntry from a JSON map
  /// 从 JSON 映射创建 ScoreHistoryEntry
  factory ScoreHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ScoreHistoryEntry(
      date: DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      grade: json['grade']?.toString() ?? '',
    );
  }

  /// Serialize this history entry to a JSON map
  /// 将此历史条目序列化为 JSON 映射
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'score': score,
        'grade': grade,
      };
}

/// Score trend analysis over time
/// 评分随时间变化的趋势分析
class ScoreTrend {
  final List<ScoreHistoryEntry> entries;
  final double averageScore;
  final int highestScore;
  final int lowestScore;
  final int scoreChangeThisWeek;
  final int scoreChangeThisMonth;

  /// Creates a ScoreTrend with computed statistics
  /// 使用计算的统计数据创建 ScoreTrend
  const ScoreTrend({
    required this.entries,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.scoreChangeThisWeek,
    required this.scoreChangeThisMonth,
  });

  /// Create a ScoreTrend by computing statistics from history entries
  /// 通过计算历史条目的统计数据创建 ScoreTrend
  factory ScoreTrend.fromEntries(List<ScoreHistoryEntry> entries) {
    if (entries.isEmpty) {
      return const ScoreTrend(
        entries: [],
        averageScore: 0,
        highestScore: 0,
        lowestScore: 0,
        scoreChangeThisWeek: 0,
        scoreChangeThisMonth: 0,
      );
    }

    final scores = entries.map((e) => e.score).toList();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    // Calculate weekly change
    final recentEntries = entries.where((e) => e.date.isAfter(weekAgo)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final weeklyChange = recentEntries.length >= 2
        ? recentEntries.last.score - recentEntries.first.score
        : 0;

    // Calculate monthly change
    final monthEntries = entries.where((e) => e.date.isAfter(monthAgo)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final monthlyChange = monthEntries.length >= 2
        ? monthEntries.last.score - monthEntries.first.score
        : 0;

    return ScoreTrend(
      entries: entries,
      averageScore: scores.reduce((a, b) => a + b) / scores.length,
      highestScore: scores.reduce((a, b) => a > b ? a : b),
      lowestScore: scores.reduce((a, b) => a < b ? a : b),
      scoreChangeThisWeek: weeklyChange,
      scoreChangeThisMonth: monthlyChange,
    );
  }

  /// Get trend direction
  /// 获取趋势方向
  String get trendDirection {
    if (scoreChangeThisWeek > 5) return 'improving';
    if (scoreChangeThisWeek < -5) return 'declining';
    return 'stable';
  }
}
