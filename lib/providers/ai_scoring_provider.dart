// =============================================================================
// ai_scoring_provider.dart — AI Scoring & Daily Review Provider
// AI 评分与每日回顾 Provider
//
// Manages AI habit scoring (4 dimensions: Consistency, Momentum, Resilience,
// Engagement), daily reviews, and health data correlations. Calls Firebase
// Cloud Functions for AI analysis and stores results in Firestore.
//
// 管理 AI 习惯评分（4 个维度：一致性、动力、韧性、参与度）、每日回顾和
// 健康数据关联分析。调用 Firebase Cloud Functions 进行 AI 分析，
// 并将结果存储在 Firestore 中。
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/ai_scoring_models.dart';
import '../models/daily_review_models.dart';
import '../models/health_data_models.dart';
import '../models/habit.dart';
import '../providers/ai_coach_provider.dart';
import '../services/firestore_service.dart';
import '../services/health_service.dart';
import '../services/subscription_service.dart';
import '../utils/date_utils.dart' as date_utils;

/// Provider for AI scoring, daily reviews, and health correlations
/// AI 评分、每日回顾和健康关联分析的 Provider
class AIScoringProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final HealthService _healthService = HealthService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();

  // State
  bool _isInitialized = false;
  bool _isLoadingScore = false;
  bool _isLoadingReview = false;
  bool _isLoadingCorrelations = false;
  bool _healthIntegrationEnabled = false;
  String? _errorMessage;
  final Set<String> _inProgressOps = {};

  // Data
  Map<String, HabitScore> _habitScores = {};
  DailyReview? _todaysReview;
  List<DailyReview> _reviewHistory = [];
  HealthCorrelationAnalysis? _healthCorrelations;
  HealthDataSummary? _healthSummary;

  // Cached computed value (invalidated when _habitScores changes)
  double? _cachedOverallAverageScore;

  /// Whether the provider has been initialized
  /// Provider 是否已初始化
  bool get isInitialized => _isInitialized;

  /// Whether a score is currently being generated
  /// 评分是否正在生成中
  bool get isLoadingScore => _isLoadingScore;

  /// Whether a daily review is currently being generated
  /// 每日回顾是否正在生成中
  bool get isLoadingReview => _isLoadingReview;

  /// Whether health correlations are currently being generated
  /// 健康关联分析是否正在生成中
  bool get isLoadingCorrelations => _isLoadingCorrelations;

  /// Whether health integration is enabled
  /// 健康集成是否已启用
  bool get healthIntegrationEnabled => _healthIntegrationEnabled;

  /// Get the current error message if any
  /// 获取当前错误消息（如果有）
  String? get errorMessage => _errorMessage;

  /// Get all habit scores keyed by habit ID
  /// 获取所有习惯评分（按习惯 ID 索引）
  Map<String, HabitScore> get habitScores => _habitScores;

  /// Get today's daily review
  /// 获取今日的每日回顾
  DailyReview? get todaysReview => _todaysReview;

  /// Get the review history list
  /// 获取回顾历史列表
  List<DailyReview> get reviewHistory => _reviewHistory;

  /// Get the health correlation analysis
  /// 获取健康关联分析
  HealthCorrelationAnalysis? get healthCorrelations => _healthCorrelations;

  /// Get the health data summary
  /// 获取健康数据摘要
  HealthDataSummary? get healthSummary => _healthSummary;

  /// Check if user can use AI reports this month
  /// 检查用户本月是否可以使用 AI 报告
  bool get canUseAIReport => _subscriptionService.canUseAIReport();

  /// Get remaining AI reports for this month
  /// 获取本月剩余 AI 报告次数
  int get remainingAIReports => _subscriptionService.getRemainingAIReports();

  /// Check if the daily review is outdated compared to current habit state
  /// 检查每日回顾是否相对于当前习惯状态已过期
  bool isDailyReviewOutdated(List<Habit> habits) {
    final review = _todaysReview;
    if (review == null) return false;
    final current = AICoachProvider.buildCompletionSnapshot(habits);
    return !listEquals(current, review.completionSnapshot);
  }

  /// Get score for a specific habit
  /// 获取特定习惯的评分
  HabitScore? getScoreForHabit(String habitId) => _habitScores[habitId];

  /// Calculate overall average score across all habits (cached)
  /// 计算所有习惯的总体平均评分（已缓存）
  double get overallAverageScore {
    if (_cachedOverallAverageScore != null) return _cachedOverallAverageScore!;
    if (_habitScores.isEmpty) {
      _cachedOverallAverageScore = 0;
      return 0;
    }
    final scores = _habitScores.values.map((s) => s.overallScore).toList();
    _cachedOverallAverageScore = scores.reduce((a, b) => a + b) / scores.length;
    return _cachedOverallAverageScore!;
  }

  /// Initialize the provider
  /// 初始化 Provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load health integration status
      _healthIntegrationEnabled = await _firestoreService
          .getHealthIntegrationEnabled();

      // Initialize health service if enabled
      if (_healthIntegrationEnabled) {
        await _healthService.initialize();
        await _healthService.checkPermissions();
      }

      // Load cached scores
      _habitScores = await _firestoreService.getAllHabitScores();
      _cachedOverallAverageScore = null; // Invalidate cache

      // Load today's review if exists
      final todayStr = date_utils.formatDateId(DateTime.now());
      _todaysReview = await _firestoreService.getDailyReview(todayStr);

      // Load recent review history
      _reviewHistory = await _firestoreService.getDailyReviewHistory(limit: 7);

      // Load latest health correlations
      if (_healthIntegrationEnabled) {
        _healthCorrelations = await _firestoreService
            .getLatestHealthCorrelation();
        _healthSummary = await _healthService.getHealthSummary(days: 7);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing AIScoringProvider: $e');
      _errorMessage = 'Failed to initialize AI scoring';
      _isInitialized = true; // Prevent infinite retry loop
      notifyListeners();
    }
  }

  /// Generate score for a single habit
  /// 为单个习惯生成评分
  Future<HabitScore?> generateHabitScore(Habit habit) async {
    if (_inProgressOps.contains('score_${habit.id}')) {
      return _habitScores[habit.id];
    }
    _inProgressOps.add('score_${habit.id}');
    try {
      // Check monthly AI report limit
      if (!_subscriptionService.canUseAIReport()) {
        _errorMessage =
            'Monthly AI report limit reached. Upgrade for more reports.';
        notifyListeners();
        return null;
      }

      _isLoadingScore = true;
      _errorMessage = null;
      notifyListeners();

      try {
        // Get completion history
        final history = await _firestoreService.getCompletionHistoryForScoring(
          habit.id,
          days: 30,
        );

        // Get longest streak from history (simplified calculation)
        int longestStreak = habit.streak;
        int currentCount = 0;
        for (final completed in history) {
          if (completed) {
            currentCount++;
            if (currentCount > longestStreak) {
              longestStreak = currentCount;
            }
          } else {
            currentCount = 0;
          }
        }

        // Prepare health data if available
        Map<String, dynamic>? healthData;
        if (_healthIntegrationEnabled && _healthSummary != null) {
          healthData = {
            'avgSteps': _healthSummary!.avgSteps.isFinite
                ? _healthSummary!.avgSteps.toInt()
                : 0,
            'avgSleep': _healthSummary!.avgSleepHours.isFinite
                ? _healthSummary!.avgSleepHours
                : 0.0,
            'avgHeartRate': _healthSummary!.avgHeartRate.isFinite
                ? _healthSummary!.avgHeartRate.toInt()
                : 0,
          };
        }

        // Call Cloud Function
        final callable = _functions.httpsCallable('generateHabitScore');
        final result = await callable.call({
          'habitName': habit.name,
          'category': habit.category.name,
          'currentStreak': habit.streak,
          'longestStreak': longestStreak,
          'totalCompletions': history.where((h) => h).length,
          'completionHistory': history,
          'healthData': healthData,
          'goalType': habit.goalType,
          'goalValue': habit.goalValue,
          'goalUnit': habit.goalUnit,
        });

        // Validate response data type before casting
        final responseData = result.data;
        if (responseData == null || responseData is! Map) {
          throw FormatException(
            'Invalid habit score response: expected Map, got ${responseData.runtimeType}',
          );
        }
        final responseMap = Map<String, dynamic>.from(responseData);

        // Parse response
        final score = HabitScore.fromJson(responseMap, habitId: habit.id);

        // Record usage after successful API call
        await _subscriptionService.recordAIReportUsage();

        // Save to Firestore
        await _firestoreService.saveHabitScore(score);

        // Update local state
        _habitScores[habit.id] = score;
        _cachedOverallAverageScore = null; // Invalidate cache

        _isLoadingScore = false;
        notifyListeners();
        return score;
      } catch (e) {
        debugPrint('Error generating habit score: $e');
        _errorMessage = 'Failed to generate habit score';
        _isLoadingScore = false;
        notifyListeners();
        return null;
      }
    } finally {
      _inProgressOps.remove('score_${habit.id}');
    }
  }

  /// Generate daily review for today
  /// 生成今日的每日回顾
  Future<DailyReview?> generateDailyReview(List<Habit> habits) async {
    if (habits.isEmpty) return null;
    if (_inProgressOps.contains('review')) return _todaysReview;

    // Check if today's review already exists to avoid duplicate API calls
    // 检查今日回顾是否已存在，以避免重复的 API 调用
    final today = DateTime.now();
    final todayStr = date_utils.formatDateId(today);
    if (_todaysReview != null && _todaysReview!.date == todayStr) {
      debugPrint(
        'generateDailyReview: today\'s review already exists, skipping',
      );
      return _todaysReview;
    }

    _inProgressOps.add('review');
    try {
      // Check monthly AI report limit
      if (!_subscriptionService.canUseAIReport()) {
        _errorMessage =
            'Monthly AI report limit reached. Upgrade for more reports.';
        notifyListeners();
        return null;
      }

      _isLoadingReview = true;
      _errorMessage = null;
      notifyListeners();

      try {
        // Prepare habit data
        final habitData = habits
            .map(
              (h) => {
                'id': h.id,
                'name': h.name,
                'category': h.category.name,
                'completed': h.isCompleted,
                'streak': h.streak,
                'goalType': h.goalType,
                'goalValue': h.goalValue,
                'goalUnit': h.goalUnit,
              },
            )
            .toList();

        // Fetch actual completion history for the 7-day range from Firestore
        final completionsByDate = <String, int>{};
        final historyFutures = habits
            .map((h) => _firestoreService.getHabitHistory(h.id, limitDays: 7))
            .toList();
        final allHistories = await Future.wait(historyFutures);
        for (final history in allHistories) {
          for (final date in history) {
            final key = date_utils.formatDateId(date);
            completionsByDate[key] = (completionsByDate[key] ?? 0) + 1;
          }
        }

        // Get weekly trend (last 7 days completion rates) from real history data
        final weeklyTrend = <double>[];
        for (int i = 6; i >= 0; i--) {
          final date = today.subtract(Duration(days: i));
          final key = date_utils.formatDateId(date);
          final completed = completionsByDate[key] ?? 0;
          weeklyTrend.add(
            habits.isNotEmpty ? (completed / habits.length) * 100 : 0,
          );
        }

        // Prepare health data if available
        Map<String, dynamic>? healthData;
        if (_healthIntegrationEnabled) {
          final todaysHealth = await _healthService.getTodaysHealthData();
          if (todaysHealth != null && todaysHealth.hasData) {
            healthData = todaysHealth.toJson();
          }
        }

        // Get previous score
        final previousReview = _reviewHistory.isNotEmpty
            ? _reviewHistory.first
            : null;
        final previousScore = previousReview?.overallScore ?? 0;

        // Call Cloud Function
        final callable = _functions.httpsCallable('generateDailyReview');
        final result = await callable.call({
          'date': todayStr,
          'habits': habitData,
          'weeklyTrend': weeklyTrend,
          'healthData': healthData,
          'previousScore': previousScore,
        });

        // Validate response data type before casting
        final responseData = result.data;
        if (responseData == null || responseData is! Map) {
          throw FormatException(
            'Invalid daily review response: expected Map, got ${responseData.runtimeType}',
          );
        }
        final responseMap = Map<String, dynamic>.from(responseData);

        // Capture completion snapshot at generation time
        responseMap['completionSnapshot'] =
            AICoachProvider.buildCompletionSnapshot(habits);

        // Parse response
        final review = DailyReview.fromJson(responseMap);

        // Record usage after successful API call
        await _subscriptionService.recordAIReportUsage();

        // Save to Firestore
        await _firestoreService.saveDailyReview(review);

        // Update local state — replace existing entry for same date
        _todaysReview = review;
        _reviewHistory.removeWhere((r) => r.date == review.date);
        _reviewHistory.insert(0, review);
        if (_reviewHistory.length > 30) {
          _reviewHistory.removeLast();
        }

        _isLoadingReview = false;
        notifyListeners();
        return review;
      } catch (e) {
        debugPrint('Error generating daily review: $e');
        _errorMessage = 'Failed to generate daily review';
        _isLoadingReview = false;
        notifyListeners();
        return null;
      }
    } finally {
      _inProgressOps.remove('review');
    }
  }

  /// Generate health correlations analysis
  /// 生成健康关联分析
  Future<HealthCorrelationAnalysis?> generateHealthCorrelations({
    required List<Habit> habits,
    String timeRange = '30d',
  }) async {
    if (_inProgressOps.contains('correlations')) return _healthCorrelations;
    _inProgressOps.add('correlations');
    try {
      if (!_healthIntegrationEnabled) {
        _errorMessage = 'Health integration is not enabled';
        notifyListeners();
        return null;
      }

      // Check monthly AI report limit
      if (!_subscriptionService.canUseAIReport()) {
        _errorMessage =
            'Monthly AI report limit reached. Upgrade for more reports.';
        notifyListeners();
        return null;
      }

      _isLoadingCorrelations = true;
      _errorMessage = null;
      notifyListeners();

      try {
        // Get health data
        final days = timeRange == '7d'
            ? 7
            : timeRange == '90d'
            ? 90
            : 30;
        final healthData = await _healthService.prepareHealthDataForAnalysis(
          days: days,
        );

        if (healthData.length < 7) {
          _errorMessage =
              'Not enough health data for analysis (need at least 7 days)';
          _isLoadingCorrelations = false;
          notifyListeners();
          return null;
        }

        // Fetch all histories in parallel (fixes N+1 query pattern)
        final historyFutures = habits
            .map((h) => _firestoreService.getHabitHistory(h.id))
            .toList();
        final allHistories = await Future.wait(historyFutures);

        // Build date -> completion count map for day-aligned health data
        final dateCompletionCount = <String, int>{};
        for (int i = 0; i < habits.length; i++) {
          final history = allHistories[i];
          for (final d in history) {
            final dateStr = date_utils.formatDateId(d);
            dateCompletionCount[dateStr] =
                (dateCompletionCount[dateStr] ?? 0) + 1;
          }
        }

        // Prepare habit data with completion dates
        final habitData = <Map<String, dynamic>>[];
        for (int i = 0; i < habits.length; i++) {
          final habit = habits[i];
          final history = allHistories[i];
          final completionDates = history
              .map((d) => date_utils.formatDateId(d))
              .toList();

          final completedInRange = completionDates.length;
          final avgRate = days > 0 ? (completedInRange / days) * 100 : 0;

          habitData.add({
            'name': habit.name,
            'category': habit.category.name,
            'completionDates': completionDates,
            'avgCompletionRate': avgRate,
          });
        }

        // Enrich health data with daily habit completion rate
        final totalHabits = habits.length;
        final enrichedHealthData = healthData.map((entry) {
          final map = Map<String, dynamic>.from(entry as Map);
          final dateStr = map['date']?.toString();
          if (dateStr != null && totalHabits > 0) {
            final completed = dateCompletionCount[dateStr] ?? 0;
            map['dailyCompletionRate'] = ((completed / totalHabits) * 100)
                .round();
          }
          return map;
        }).toList();

        // Call Cloud Function
        final callable = _functions.httpsCallable('generateHealthCorrelations');
        final result = await callable.call({
          'timeRange': timeRange,
          'habitData': habitData,
          'healthData': enrichedHealthData,
        });

        // Validate response data type before casting
        final responseData = result.data;
        if (responseData == null || responseData is! Map) {
          throw FormatException(
            'Invalid health correlations response: expected Map, got ${responseData.runtimeType}',
          );
        }
        final responseMap = Map<String, dynamic>.from(responseData);

        // Parse response
        final analysis = HealthCorrelationAnalysis.fromJson(responseMap);

        // Record usage after successful API call
        await _subscriptionService.recordAIReportUsage();

        // Save to Firestore
        await _firestoreService.saveHealthCorrelation(analysis);

        // Update local state
        _healthCorrelations = analysis;

        _isLoadingCorrelations = false;
        notifyListeners();
        return analysis;
      } catch (e) {
        debugPrint('Error generating health correlations: $e');
        _errorMessage = 'Failed to generate health correlations';
        _isLoadingCorrelations = false;
        notifyListeners();
        return null;
      }
    } finally {
      _inProgressOps.remove('correlations');
    }
  }

  /// Enable health integration
  /// 启用健康集成
  Future<bool> enableHealthIntegration() async {
    try {
      // Request permissions
      final result = await _healthService.requestPermissions();
      if (!result.granted) {
        _errorMessage = result.error ?? 'Health permissions not granted';
        notifyListeners();
        return false;
      }

      // Save preference
      await _firestoreService.saveHealthIntegrationEnabled(true);
      _healthIntegrationEnabled = true;

      // Load health data
      _healthSummary = await _healthService.getHealthSummary(days: 7);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error enabling health integration: $e');
      _errorMessage = 'Failed to enable health integration';
      notifyListeners();
      return false;
    }
  }

  /// Disable health integration
  /// 禁用健康集成
  Future<void> disableHealthIntegration() async {
    try {
      await _firestoreService.saveHealthIntegrationEnabled(false);
      await _healthService.revokePermissions();

      _healthIntegrationEnabled = false;
      _healthSummary = null;
      _healthCorrelations = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Error disabling health integration: $e');
    }
  }

  /// Refresh health summary
  /// 刷新健康摘要
  Future<void> refreshHealthSummary() async {
    if (!_healthIntegrationEnabled) return;

    try {
      _healthSummary = await _healthService.getHealthSummary(days: 7);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing health summary: $e');
    }
  }

  /// Get score history for a habit
  /// 获取习惯的评分历史趋势
  Future<ScoreTrend> getScoreTrend(String habitId) async {
    try {
      final entries = await _firestoreService.getScoreHistory(habitId);
      return ScoreTrend.fromEntries(entries);
    } catch (e) {
      debugPrint('Error getting score trend: $e');
      return ScoreTrend.fromEntries([]);
    }
  }

  /// Clear all user-specific data on logout
  /// 登出时清除所有用户数据
  void clearUserData() {
    _inProgressOps.clear();
    _habitScores = {};
    _todaysReview = null;
    _reviewHistory = [];
    _healthCorrelations = null;
    _healthSummary = null;
    _cachedOverallAverageScore = null;
    _isLoadingScore = false;
    _isLoadingReview = false;
    _isLoadingCorrelations = false;
    _healthIntegrationEnabled = false;
    _errorMessage = null;
    _isInitialized = false;
    notifyListeners();
  }

  /// Clear error message
  /// 清除错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
