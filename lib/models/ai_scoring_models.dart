// AI Scoring models for habit performance analysis

/// Individual score component for a dimension of habit performance
class ScoreComponent {
  final int score;
  final String analysis;

  const ScoreComponent({
    required this.score,
    required this.analysis,
  });

  factory ScoreComponent.fromJson(Map<String, dynamic> json) {
    return ScoreComponent(
      score: (json['score'] as num?)?.toInt() ?? 0,
      analysis: json['analysis']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'analysis': analysis,
      };
}

/// Breakdown of habit score across multiple dimensions
class ScoreBreakdown {
  final ScoreComponent consistency;
  final ScoreComponent momentum;
  final ScoreComponent resilience;
  final ScoreComponent engagement;

  const ScoreBreakdown({
    required this.consistency,
    required this.momentum,
    required this.resilience,
    required this.engagement,
  });

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

  Map<String, dynamic> toJson() => {
        'consistency': consistency.toJson(),
        'momentum': momentum.toJson(),
        'resilience': resilience.toJson(),
        'engagement': engagement.toJson(),
      };

  /// Get average score across all components
  double get averageScore =>
      (consistency.score + momentum.score + resilience.score + engagement.score) /
      4;
}

/// Comprehensive habit score from AI analysis
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

  /// Get color based on grade
  bool get isExcellent => grade.startsWith('A');
  bool get isGood => grade.startsWith('B');
  bool get isAverage => grade.startsWith('C');
  bool get needsImprovement => grade.startsWith('D') || grade.startsWith('F');

  /// Get score tier description
  String get scoreTier {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Great';
    if (overallScore >= 70) return 'Good';
    if (overallScore >= 60) return 'Fair';
    return 'Needs Work';
  }

  /// Calculate score change from previous
  int scoreChange(HabitScore? previous) {
    if (previous == null) return 0;
    return overallScore - previous.overallScore;
  }
}

/// Historical score entry for tracking progress over time
class ScoreHistoryEntry {
  final DateTime date;
  final int score;
  final String grade;

  const ScoreHistoryEntry({
    required this.date,
    required this.score,
    required this.grade,
  });

  factory ScoreHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ScoreHistoryEntry(
      date: DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      grade: json['grade']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'score': score,
        'grade': grade,
      };
}

/// Score trend analysis over time
class ScoreTrend {
  final List<ScoreHistoryEntry> entries;
  final double averageScore;
  final int highestScore;
  final int lowestScore;
  final int scoreChangeThisWeek;
  final int scoreChangeThisMonth;

  const ScoreTrend({
    required this.entries,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.scoreChangeThisWeek,
    required this.scoreChangeThisMonth,
  });

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
  String get trendDirection {
    if (scoreChangeThisWeek > 5) return 'improving';
    if (scoreChangeThisWeek < -5) return 'declining';
    return 'stable';
  }
}
