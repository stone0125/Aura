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
/// 单个习惯的每日表现评分
class HabitDayScore {
  final String habitId;
  final int score;
  final HabitDayStatus status;
  final String comment;

  /// Creates a HabitDayScore with habit ID, score, status, and comment
  /// 使用习惯 ID、分数、状态和评语创建 HabitDayScore
  const HabitDayScore({
    required this.habitId,
    required this.score,
    required this.status,
    required this.comment,
  });

  /// Create a HabitDayScore from a JSON map
  /// 从 JSON 映射创建 HabitDayScore
  factory HabitDayScore.fromJson(Map<String, dynamic> json) {
    return HabitDayScore(
      habitId: json['habitId']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      status: HabitDayStatus.fromString(json['status']?.toString() ?? ''),
      comment: json['comment']?.toString() ?? '',
    );
  }

  /// Serialize this day score to a JSON map
  /// 将此每日评分序列化为 JSON 映射
  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'score': score,
        'status': status.value,
        'comment': comment,
      };
}

/// Status of a habit for the day
/// 习惯的当日状态
enum HabitDayStatus {
  completed('completed'),
  missed('missed'),
  streakMilestone('streak_milestone'),
  streakBroken('streak_broken');

  final String value;
  const HabitDayStatus(this.value);

  /// Parse a HabitDayStatus from a string value
  /// 从字符串值解析 HabitDayStatus
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

  /// Get display name for the habit day status
  /// 获取习惯当日状态的显示名称
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

  /// Check if this status represents a positive outcome
  /// 检查此状态是否代表积极结果
  bool get isPositive =>
      this == HabitDayStatus.completed || this == HabitDayStatus.streakMilestone;
}

/// AI Coach commentary for the daily review
/// 每日回顾的 AI 教练评语
class CoachComments {
  final String summary;
  final String highlight;
  final String? concern;
  final String actionItem;

  /// Creates CoachComments with summary, highlight, concern, and action item
  /// 使用总结、亮点、关注点和行动项创建 CoachComments
  const CoachComments({
    required this.summary,
    required this.highlight,
    this.concern,
    required this.actionItem,
  });

  /// Create CoachComments from a JSON map
  /// 从 JSON 映射创建 CoachComments
  factory CoachComments.fromJson(Map<String, dynamic> json) {
    return CoachComments(
      summary: json['summary']?.toString() ?? '',
      highlight: json['highlight']?.toString() ?? '',
      concern: json['concern']?.toString(),
      actionItem: json['actionItem']?.toString() ?? '',
    );
  }

  /// Serialize this coach comments to a JSON map
  /// 将此教练评语序列化为 JSON 映射
  Map<String, dynamic> toJson() => {
        'summary': summary,
        'highlight': highlight,
        'concern': concern,
        'actionItem': actionItem,
      };
}

/// Health-related insights from daily review
/// 每日回顾中的健康相关洞察
class HealthInsights {
  final String? correlation;
  final String? recommendation;

  /// Creates HealthInsights with optional correlation and recommendation
  /// 使用可选的关联分析和建议创建 HealthInsights
  const HealthInsights({
    this.correlation,
    this.recommendation,
  });

  /// Create HealthInsights from an optional JSON map
  /// 从可选的 JSON 映射创建 HealthInsights
  factory HealthInsights.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const HealthInsights();
    }
    return HealthInsights(
      correlation: json['correlation']?.toString(),
      recommendation: json['recommendation']?.toString(),
    );
  }

  /// Serialize this health insights to a JSON map
  /// 将此健康洞察序列化为 JSON 映射
  Map<String, dynamic> toJson() => {
        'correlation': correlation,
        'recommendation': recommendation,
      };

  /// Check if there is any meaningful data
  /// 检查是否有有意义的数据
  bool get hasData => correlation != null || recommendation != null;
}

/// Comprehensive daily review from AI coach
/// AI 教练的综合每日回顾
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

  /// Creates a DailyReview with all required and optional fields
  /// 使用所有必需和可选字段创建 DailyReview
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

  /// Create a DailyReview from a JSON map with safe parsing
  /// 从 JSON 映射创建 DailyReview，带有安全解析
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

  /// Serialize this daily review to a JSON map
  /// 将此每日回顾序列化为 JSON 映射
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
  /// 检查分数是否提升
  bool get isImprovement => scoreChange > 0;

  /// Check if score declined
  /// 检查分数是否下降
  bool get isDecline => scoreChange < 0;

  /// Get completion count from habit scores
  /// 从习惯评分中获取完成数量
  int get completedCount =>
      habitScores.where((h) => h.status.isPositive).length;

  /// Get total habits count
  /// 获取习惯总数
  int get totalHabits => habitScores.length;

  /// Get completion percentage
  /// 获取完成百分比
  double get completionPercentage =>
      totalHabits > 0 ? (completedCount / totalHabits) * 100 : 0;

  /// Check if it's a perfect day
  /// 检查是否是完美的一天
  bool get isPerfectDay => completedCount == totalHabits && totalHabits > 0;

  /// Get score tier
  /// 获取分数等级
  String get scoreTier {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Great';
    if (overallScore >= 70) return 'Good';
    if (overallScore >= 60) return 'Fair';
    return 'Needs Improvement';
  }
}

/// Summary of daily reviews over a period
/// 一段时期内每日回顾的总结
class DailyReviewSummary {
  final List<DailyReview> reviews;
  final double averageScore;
  final int perfectDays;
  final int totalDays;
  final String bestDay;
  final String worstDay;

  /// Creates a DailyReviewSummary with aggregated statistics
  /// 使用汇总统计数据创建 DailyReviewSummary
  const DailyReviewSummary({
    required this.reviews,
    required this.averageScore,
    required this.perfectDays,
    required this.totalDays,
    required this.bestDay,
    required this.worstDay,
  });

  /// Create a DailyReviewSummary by computing stats from a list of reviews
  /// 通过计算回顾列表的统计数据创建 DailyReviewSummary
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
  /// 获取一致性评级
  String get consistencyRating {
    final perfectPercentage = totalDays > 0 ? (perfectDays / totalDays) * 100 : 0;
    if (perfectPercentage >= 80) return 'Excellent';
    if (perfectPercentage >= 60) return 'Good';
    if (perfectPercentage >= 40) return 'Developing';
    return 'Building';
  }
}
