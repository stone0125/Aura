// Health data models for health-habit correlation analysis

/// Single day's health data point
class HealthDataPoint {
  final DateTime date;
  final int? steps;
  final double? sleepHours;
  final String? sleepQuality;
  final int? heartRate;
  final int? activeMinutes;
  final int? caloriesBurned;

  const HealthDataPoint({
    required this.date,
    this.steps,
    this.sleepHours,
    this.sleepQuality,
    this.heartRate,
    this.activeMinutes,
    this.caloriesBurned,
  });

  factory HealthDataPoint.fromJson(Map<String, dynamic> json) {
    return HealthDataPoint(
      date: json['date'] != null
          ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now())
          : DateTime.now(),
      steps: (json['steps'] as num?)?.toInt(),
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      sleepQuality: json['sleepQuality']?.toString(),
      heartRate: (json['heartRate'] as num?)?.toInt(),
      activeMinutes: (json['activeMinutes'] as num?)?.toInt(),
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'steps': steps,
        'sleepHours': sleepHours,
        'sleepQuality': sleepQuality,
        'heartRate': heartRate,
        'activeMinutes': activeMinutes,
        'caloriesBurned': caloriesBurned,
      };

  /// Check if has meaningful data
  bool get hasData =>
      steps != null ||
      sleepHours != null ||
      heartRate != null ||
      activeMinutes != null;

  /// Get formatted date string
  String get dateString =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Aggregated health data summary
class HealthDataSummary {
  final int totalDays;
  final double avgSteps;
  final double avgSleepHours;
  final double avgHeartRate;
  final double avgActiveMinutes;
  final double avgCaloriesBurned;

  const HealthDataSummary({
    required this.totalDays,
    required this.avgSteps,
    required this.avgSleepHours,
    required this.avgHeartRate,
    required this.avgActiveMinutes,
    required this.avgCaloriesBurned,
  });

  factory HealthDataSummary.fromDataPoints(List<HealthDataPoint> points) {
    if (points.isEmpty) {
      return const HealthDataSummary(
        totalDays: 0,
        avgSteps: 0,
        avgSleepHours: 0,
        avgHeartRate: 0,
        avgActiveMinutes: 0,
        avgCaloriesBurned: 0,
      );
    }

    // Single-pass accumulation instead of 5 separate .where() calls
    int stepsSum = 0, stepsCount = 0;
    double sleepSum = 0;
    int sleepCount = 0;
    int heartSum = 0, heartCount = 0;
    int activeSum = 0, activeCount = 0;
    int calorieSum = 0, calorieCount = 0;

    for (final p in points) {
      if (p.steps != null) {
        stepsSum += p.steps!;
        stepsCount++;
      }
      if (p.sleepHours != null) {
        sleepSum += p.sleepHours!;
        sleepCount++;
      }
      if (p.heartRate != null) {
        heartSum += p.heartRate!;
        heartCount++;
      }
      if (p.activeMinutes != null) {
        activeSum += p.activeMinutes!;
        activeCount++;
      }
      if (p.caloriesBurned != null) {
        calorieSum += p.caloriesBurned!;
        calorieCount++;
      }
    }

    return HealthDataSummary(
      totalDays: points.length,
      avgSteps: stepsCount > 0 ? stepsSum / stepsCount : 0,
      avgSleepHours: sleepCount > 0 ? sleepSum / sleepCount : 0,
      avgHeartRate: heartCount > 0 ? heartSum / heartCount : 0,
      avgActiveMinutes: activeCount > 0 ? activeSum / activeCount : 0,
      avgCaloriesBurned: calorieCount > 0 ? calorieSum / calorieCount : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalDays': totalDays,
        'avgSteps': avgSteps,
        'avgSleepHours': avgSleepHours,
        'avgHeartRate': avgHeartRate,
        'avgActiveMinutes': avgActiveMinutes,
        'avgCaloriesBurned': avgCaloriesBurned,
      };
}

/// Correlation impact level
enum CorrelationImpact {
  strongPositive('strong_positive'),
  moderatePositive('moderate_positive'),
  weakPositive('weak_positive'),
  none('none'),
  weakNegative('weak_negative'),
  moderateNegative('moderate_negative'),
  strongNegative('strong_negative');

  final String value;
  const CorrelationImpact(this.value);

  static CorrelationImpact fromString(String value) {
    switch (value.toLowerCase()) {
      case 'strong_positive':
        return CorrelationImpact.strongPositive;
      case 'moderate_positive':
        return CorrelationImpact.moderatePositive;
      case 'weak_positive':
        return CorrelationImpact.weakPositive;
      case 'none':
        return CorrelationImpact.none;
      case 'weak_negative':
        return CorrelationImpact.weakNegative;
      case 'moderate_negative':
        return CorrelationImpact.moderateNegative;
      case 'strong_negative':
        return CorrelationImpact.strongNegative;
      default:
        return CorrelationImpact.none;
    }
  }

  String get displayName {
    switch (this) {
      case CorrelationImpact.strongPositive:
        return 'Strong Positive';
      case CorrelationImpact.moderatePositive:
        return 'Moderate Positive';
      case CorrelationImpact.weakPositive:
        return 'Weak Positive';
      case CorrelationImpact.none:
        return 'No Correlation';
      case CorrelationImpact.weakNegative:
        return 'Weak Negative';
      case CorrelationImpact.moderateNegative:
        return 'Moderate Negative';
      case CorrelationImpact.strongNegative:
        return 'Strong Negative';
    }
  }

  bool get isPositive =>
      this == CorrelationImpact.strongPositive ||
      this == CorrelationImpact.moderatePositive ||
      this == CorrelationImpact.weakPositive;

  bool get isNegative =>
      this == CorrelationImpact.strongNegative ||
      this == CorrelationImpact.moderateNegative ||
      this == CorrelationImpact.weakNegative;

  bool get isSignificant =>
      this == CorrelationImpact.strongPositive ||
      this == CorrelationImpact.strongNegative ||
      this == CorrelationImpact.moderatePositive ||
      this == CorrelationImpact.moderateNegative;
}

/// Single correlation between a health metric and habits
class HealthCorrelation {
  final HealthMetricType metric;
  final CorrelationImpact impact;
  final double correlation;
  final String insight;
  final String recommendation;

  const HealthCorrelation({
    required this.metric,
    required this.impact,
    required this.correlation,
    required this.insight,
    required this.recommendation,
  });

  factory HealthCorrelation.fromJson(Map<String, dynamic> json) {
    return HealthCorrelation(
      metric: HealthMetricType.fromString(json['metric']?.toString() ?? ''),
      impact: CorrelationImpact.fromString(json['impact']?.toString() ?? ''),
      correlation: (json['correlation'] as num?)?.toDouble() ?? 0,
      insight: json['insight']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'metric': metric.value,
        'impact': impact.value,
        'correlation': correlation,
        'insight': insight,
        'recommendation': recommendation,
      };
}

/// Types of health metrics
enum HealthMetricType {
  sleep('sleep'),
  steps('steps'),
  heartRate('heartRate'),
  activeMinutes('activeMinutes'),
  calories('calories');

  final String value;
  const HealthMetricType(this.value);

  static HealthMetricType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sleep':
        return HealthMetricType.sleep;
      case 'steps':
        return HealthMetricType.steps;
      case 'heartrate':
        return HealthMetricType.heartRate;
      case 'activeminutes':
        return HealthMetricType.activeMinutes;
      case 'calories':
        return HealthMetricType.calories;
      default:
        return HealthMetricType.steps;
    }
  }

  String get displayName {
    switch (this) {
      case HealthMetricType.sleep:
        return 'Sleep';
      case HealthMetricType.steps:
        return 'Steps';
      case HealthMetricType.heartRate:
        return 'Heart Rate';
      case HealthMetricType.activeMinutes:
        return 'Active Minutes';
      case HealthMetricType.calories:
        return 'Calories';
    }
  }

  String get unit {
    switch (this) {
      case HealthMetricType.sleep:
        return 'hours';
      case HealthMetricType.steps:
        return 'steps';
      case HealthMetricType.heartRate:
        return 'bpm';
      case HealthMetricType.activeMinutes:
        return 'min';
      case HealthMetricType.calories:
        return 'kcal';
    }
  }
}

/// Optimal range for a health metric
class OptimalRange {
  final double min;
  final double max;
  final String description;

  const OptimalRange({
    required this.min,
    required this.max,
    required this.description,
  });

  factory OptimalRange.fromJson(Map<String, dynamic> json) {
    return OptimalRange(
      min: (json['min'] as num?)?.toDouble() ?? 0,
      max: (json['max'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
        'description': description,
      };

  /// Check if a value is within optimal range
  bool isOptimal(double value) => value >= min && value <= max;

  /// Get range as formatted string
  String get rangeString => '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)}';
}

/// Comprehensive health-habit correlation analysis
class HealthCorrelationAnalysis {
  final String timeRange;
  final List<HealthCorrelation> correlations;
  final Map<HealthMetricType, OptimalRange> optimalConditions;
  final List<String> keyFindings;
  final String actionPlan;
  final DateTime generatedAt;

  const HealthCorrelationAnalysis({
    required this.timeRange,
    required this.correlations,
    required this.optimalConditions,
    required this.keyFindings,
    required this.actionPlan,
    required this.generatedAt,
  });

  factory HealthCorrelationAnalysis.fromJson(Map<String, dynamic> json) {
    // Parse correlations
    final correlationsList = (json['correlations'] as List?)
            ?.where((e) => e != null && e is Map)
            .map((e) => HealthCorrelation.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    // Parse optimal conditions
    final optimalMap = <HealthMetricType, OptimalRange>{};
    final rawOptimal = json['optimalConditions'];
    final optimalJson = rawOptimal is Map ? Map<String, dynamic>.from(rawOptimal) : null;
    if (optimalJson != null) {
      for (final key in optimalJson.keys) {
        final metricType = HealthMetricType.fromString(key);
        final rangeData = optimalJson[key];
        if (rangeData is Map) {
          optimalMap[metricType] =
              OptimalRange.fromJson(Map<String, dynamic>.from(rangeData));
        }
      }
    }

    return HealthCorrelationAnalysis(
      timeRange: json['timeRange']?.toString() ?? '30d',
      correlations: correlationsList,
      optimalConditions: optimalMap,
      keyFindings: (json['keyFindings'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      actionPlan: json['actionPlan']?.toString() ?? '',
      generatedAt: json['generatedAt'] != null
          ? (DateTime.tryParse(json['generatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final optimalJson = <String, dynamic>{};
    for (final entry in optimalConditions.entries) {
      optimalJson[entry.key.value] = entry.value.toJson();
    }

    return {
      'timeRange': timeRange,
      'correlations': correlations.map((e) => e.toJson()).toList(),
      'optimalConditions': optimalJson,
      'keyFindings': keyFindings,
      'actionPlan': actionPlan,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  /// Get strongest positive correlation
  HealthCorrelation? get strongestPositive {
    final positive =
        correlations.where((c) => c.impact.isPositive).toList();
    if (positive.isEmpty) return null;
    positive.sort((a, b) => b.correlation.compareTo(a.correlation));
    return positive.first;
  }

  /// Get strongest negative correlation
  HealthCorrelation? get strongestNegative {
    final negative =
        correlations.where((c) => c.impact.isNegative).toList();
    if (negative.isEmpty) return null;
    negative.sort((a, b) => a.correlation.compareTo(b.correlation));
    return negative.first;
  }

  /// Get all significant correlations
  List<HealthCorrelation> get significantCorrelations =>
      correlations.where((c) => c.impact.isSignificant).toList();
}
