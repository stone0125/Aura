// =============================================================================
// daily_review_models.dart — Daily Review Data Models
// 每日回顾数据模型
//
// Models for AI-generated daily review reports. Contains HabitDayScore
// (individual habit performance) and DailyReview (full day summary with
// overall score, highlights, and recommendations).
//
// AI 生成的每日回顾报告的数据模型。包含 HabitDayScore（单个习惯表现）
// 和 DailyReview（包含综合评分、亮点和建议的全天总结）。
// =============================================================================

/// Individual habit's daily performance score
class HabitDayScore {
  final String habitId;
  final int score;
  final HabitDayStatus status;
  final String comment;

  const HabitDayScore({
    required this.habitId,
    required this.score,
    required this.status,
    required this.comment,
  });

  factory HabitDayScore.fromJson(Map<String, dynamic> json) {
    return HabitDayScore(
      habitId: json['habitId']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      status: HabitDayStatus.fromString(json['status']?.toString() ?? ''),
      comment: json['comment']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'score': score,
        'status': status.value,
        'comment': comment,
      };
}

/// Status of a habit for the day
enum HabitDayStatus {
  completed('completed'),
  missed('missed'),
  streakMilestone('streak_milestone'),
  streakBroken('streak_broken');

  final String value;
  const HabitDayStatus(this.value);

  static HabitDayStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
        return HabitDayStatus.completed;
      case 'missed':
        return HabitDayStatus.missed;
      case 'streak_milestone':
        return HabitDayStatus.streakMilestone;
      case 'streak_broken':
        return HabitDayStatus.streakBroken;
      default:
        return HabitDayStatus.missed;
    }
  }

  String get displayName {
    switch (this) {
      case HabitDayStatus.completed:
        return 'Completed';
      case HabitDayStatus.missed:
        return 'Missed';
      case HabitDayStatus.streakMilestone:
        return 'Milestone!';
      case HabitDayStatus.streakBroken:
        return 'Streak Broken';
    }
  }

  bool get isPositive =>
      this == HabitDayStatus.completed || this == HabitDayStatus.streakMilestone;
}

/// AI Coach commentary for the daily review
class CoachComments {
  final String summary;
  final String highlight;
  final String? concern;
  final String actionItem;

  const CoachComments({
    required this.summary,
    required this.highlight,
    this.concern,
    required this.actionItem,
  });

  factory CoachComments.fromJson(Map<String, dynamic> json) {
    return CoachComments(
      summary: json['summary']?.toString() ?? '',
      highlight: json['highlight']?.toString() ?? '',
      concern: json['concern']?.toString(),
      actionItem: json['actionItem']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'highlight': highlight,
        'concern': concern,
        'actionItem': actionItem,
      };
}

/// Health-related insights from daily review
class HealthInsights {
  final String? correlation;
  final String? recommendation;

  const HealthInsights({
    this.correlation,
    this.recommendation,
  });

  factory HealthInsights.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const HealthInsights();
    }
    return HealthInsights(
      correlation: json['correlation']?.toString(),
      recommendation: json['recommendation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'correlation': correlation,
        'recommendation': recommendation,
      };

  bool get hasData => correlation != null || recommendation != null;
}

/// Comprehensive daily review from AI coach
class DailyReview {
  final String date;
  final int overallScore;
  final int scoreChange;
  final String grade;
  final List<HabitDayScore> habitScores;
  final CoachComments coachComments;
  final HealthInsights healthInsights;
  final String motivationalMessage;
  final String tomorrowFocus;
  final DateTime generatedAt;
  final List<String> completionSnapshot; // Sorted habit IDs completed at generation time

  const DailyReview({
    required this.date,
    required this.overallScore,
    required this.scoreChange,
    required this.grade,
    required this.habitScores,
    required this.coachComments,
    required this.healthInsights,
    required this.motivationalMessage,
    required this.tomorrowFocus,
    required this.generatedAt,
    this.completionSnapshot = const [],
  });

  factory DailyReview.fromJson(Map<String, dynamic> json) {
    return DailyReview(
      date: json['date']?.toString() ?? DateTime.now().toIso8601String().split('T')[0],
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
      scoreChange: (json['scoreChange'] as num?)?.toInt() ?? 0,
      grade: json['grade']?.toString() ?? 'N/A',
      habitScores: (json['habitScores'] as List?)
              ?.where((e) => e != null && e is Map)
              .map((e) => HabitDayScore.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      coachComments: CoachComments.fromJson(
          json['coachComments'] is Map ? Map<String, dynamic>.from(json['coachComments']) : {}),
      healthInsights: HealthInsights.fromJson(
          json['healthInsights'] is Map ? Map<String, dynamic>.from(json['healthInsights']) : null),
      motivationalMessage: json['motivationalMessage']?.toString() ?? '',
      tomorrowFocus: json['tomorrowFocus']?.toString() ?? '',
      generatedAt: json['generatedAt'] != null
          ? (DateTime.tryParse(json['generatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      completionSnapshot: json['completionSnapshot'] is List
          ? (json['completionSnapshot'] as List)
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'overallScore': overallScore,
        'scoreChange': scoreChange,
        'grade': grade,
        'habitScores': habitScores.map((e) => e.toJson()).toList(),
        'coachComments': coachComments.toJson(),
        'healthInsights': healthInsights.toJson(),
        'motivationalMessage': motivationalMessage,
        'tomorrowFocus': tomorrowFocus,
        'generatedAt': generatedAt.toIso8601String(),
        'completionSnapshot': completionSnapshot,
      };

  /// Check if score improved
  bool get isImprovement => scoreChange > 0;

  /// Check if score declined
  bool get isDecline => scoreChange < 0;

  /// Get completion count from habit scores
  int get completedCount =>
      habitScores.where((h) => h.status.isPositive).length;

  /// Get total habits count
  int get totalHabits => habitScores.length;

  /// Get completion percentage
  double get completionPercentage =>
      totalHabits > 0 ? (completedCount / totalHabits) * 100 : 0;

  /// Check if it's a perfect day
  bool get isPerfectDay => completedCount == totalHabits && totalHabits > 0;

  /// Get score tier
  String get scoreTier {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Great';
    if (overallScore >= 70) return 'Good';
    if (overallScore >= 60) return 'Fair';
    return 'Needs Improvement';
  }
}

/// Summary of daily reviews over a period
class DailyReviewSummary {
  final List<DailyReview> reviews;
  final double averageScore;
  final int perfectDays;
  final int totalDays;
  final String bestDay;
  final String worstDay;

  const DailyReviewSummary({
    required this.reviews,
    required this.averageScore,
    required this.perfectDays,
    required this.totalDays,
    required this.bestDay,
    required this.worstDay,
  });

  factory DailyReviewSummary.fromReviews(List<DailyReview> reviews) {
    if (reviews.isEmpty) {
      return const DailyReviewSummary(
        reviews: [],
        averageScore: 0,
        perfectDays: 0,
        totalDays: 0,
        bestDay: '',
        worstDay: '',
      );
    }

    final scores = reviews.map((r) => r.overallScore).toList();
    final highestScore = scores.reduce((a, b) => a > b ? a : b);
    final lowestScore = scores.reduce((a, b) => a < b ? a : b);

    return DailyReviewSummary(
      reviews: reviews,
      averageScore: scores.reduce((a, b) => a + b) / scores.length,
      perfectDays: reviews.where((r) => r.isPerfectDay).length,
      totalDays: reviews.length,
      bestDay: reviews.firstWhere((r) => r.overallScore == highestScore).date,
      worstDay: reviews.firstWhere((r) => r.overallScore == lowestScore).date,
    );
  }

  /// Get consistency rating
  String get consistencyRating {
    final perfectPercentage = totalDays > 0 ? (perfectDays / totalDays) * 100 : 0;
    if (perfectPercentage >= 80) return 'Excellent';
    if (perfectPercentage >= 60) return 'Good';
    if (perfectPercentage >= 40) return 'Developing';
    return 'Building';
  }
}
