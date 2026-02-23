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

/// Provider for AI scoring, daily reviews, and health correlations
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

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoadingScore => _isLoadingScore;
  bool get isLoadingReview => _isLoadingReview;
  bool get isLoadingCorrelations => _isLoadingCorrelations;
  bool get healthIntegrationEnabled => _healthIntegrationEnabled;
  String? get errorMessage => _errorMessage;
  Map<String, HabitScore> get habitScores => _habitScores;
  DailyReview? get todaysReview => _todaysReview;
  List<DailyReview> get reviewHistory => _reviewHistory;
  HealthCorrelationAnalysis? get healthCorrelations => _healthCorrelations;
  HealthDataSummary? get healthSummary => _healthSummary;

  /// Check if user can use AI reports this month
  bool get canUseAIReport => _subscriptionService.canUseAIReport();

  /// Get remaining AI reports for this month
  int get remainingAIReports => _subscriptionService.getRemainingAIReports();

  /// Check if the daily review is outdated compared to current habit state
  bool isDailyReviewOutdated(List<Habit> habits) {
    final review = _todaysReview;
    if (review == null) return false;
    final current = AICoachProvider.buildCompletionSnapshot(habits);
    return !listEquals(current, review.completionSnapshot);
  }

  /// Get score for a specific habit
  HabitScore? getScoreForHabit(String habitId) => _habitScores[habitId];

  /// Calculate overall average score across all habits (cached)
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
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load health integration status
      _healthIntegrationEnabled =
          await _firestoreService.getHealthIntegrationEnabled();

      // Initialize health service if enabled
      if (_healthIntegrationEnabled) {
        await _healthService.initialize();
        await _healthService.checkPermissions();
      }

      // Load cached scores
      _habitScores = await _firestoreService.getAllHabitScores();
      _cachedOverallAverageScore = null; // Invalidate cache

      // Load today's review if exists
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      _todaysReview = await _firestoreService.getDailyReview(todayStr);

      // Load recent review history
      _reviewHistory = await _firestoreService.getDailyReviewHistory(limit: 7);

      // Load latest health correlations
      if (_healthIntegrationEnabled) {
        _healthCorrelations =
            await _firestoreService.getLatestHealthCorrelation();
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
  Future<HabitScore?> generateHabitScore(Habit habit) async {
    if (_inProgressOps.contains('score')) return _habitScores[habit.id];
    _inProgressOps.add('score');
    try {
    // Check monthly AI report limit
    if (!_subscriptionService.canUseAIReport()) {
      _errorMessage = 'Monthly AI report limit reached. Upgrade for more reports.';
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
          'avgSteps': _healthSummary!.avgSteps.toInt(),
          'avgSleep': _healthSummary!.avgSleepHours,
          'avgHeartRate': _healthSummary!.avgHeartRate.toInt(),
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
      });

      // Validate response data type before casting
      final responseData = result.data;
      if (responseData == null || responseData is! Map) {
        throw FormatException('Invalid habit score response: expected Map, got ${responseData.runtimeType}');
      }
      final responseMap = Map<String, dynamic>.from(responseData);

      // Parse response
      final score = HabitScore.fromJson(
        responseMap,
        habitId: habit.id,
      );

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
      _inProgressOps.remove('score');
    }
  }

  /// Generate daily review for today
  Future<DailyReview?> generateDailyReview(List<Habit> habits) async {
    if (habits.isEmpty) return null;
    if (_inProgressOps.contains('review')) return _todaysReview;
    _inProgressOps.add('review');
    try {

    // Check monthly AI report limit
    if (!_subscriptionService.canUseAIReport()) {
      _errorMessage = 'Monthly AI report limit reached. Upgrade for more reports.';
      notifyListeners();
      return null;
    }

    _isLoadingReview = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Prepare habit data
      final habitData = habits
          .map((h) => {
                'id': h.id,
                'name': h.name,
                'category': h.category.name,
                'completed': h.isCompleted,
                'streak': h.streak,
              })
          .toList();

      // Fetch actual completion history for the 7-day range from Firestore
      final completionsByDate = <String, int>{};
      final historyFutures = habits.map((h) =>
          _firestoreService.getHabitHistory(h.id, limitDays: 7)).toList();
      final allHistories = await Future.wait(historyFutures);
      for (final history in allHistories) {
        for (final date in history) {
          final key = '${date.year}-${date.month}-${date.day}';
          completionsByDate[key] = (completionsByDate[key] ?? 0) + 1;
        }
      }

      // Get weekly trend (last 7 days completion rates) from real history data
      final weeklyTrend = <double>[];
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final key = '${date.year}-${date.month}-${date.day}';
        final completed = completionsByDate[key] ?? 0;
        weeklyTrend.add(habits.isNotEmpty ? (completed / habits.length) * 100 : 0);
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
      final previousReview = _reviewHistory.isNotEmpty ? _reviewHistory.first : null;
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
        throw FormatException('Invalid daily review response: expected Map, got ${responseData.runtimeType}');
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
      _errorMessage = 'Monthly AI report limit reached. Upgrade for more reports.';
      notifyListeners();
      return null;
    }

    _isLoadingCorrelations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get health data
      final days = timeRange == '7d' ? 7 : timeRange == '90d' ? 90 : 30;
      final healthData = await _healthService.prepareHealthDataForAnalysis(days: days);

      if (healthData.length < 7) {
        _errorMessage = 'Not enough health data for analysis (need at least 7 days)';
        _isLoadingCorrelations = false;
        notifyListeners();
        return null;
      }

      // Fetch all histories in parallel (fixes N+1 query pattern)
      final historyFutures = habits.map((h) => _firestoreService.getHabitHistory(h.id)).toList();
      final allHistories = await Future.wait(historyFutures);

      // Prepare habit data with completion dates
      final habitData = <Map<String, dynamic>>[];
      for (int i = 0; i < habits.length; i++) {
        final habit = habits[i];
        final history = allHistories[i];
        final completionDates = history
            .map((d) =>
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')
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

      // Call Cloud Function
      final callable = _functions.httpsCallable('generateHealthCorrelations');
      final result = await callable.call({
        'timeRange': timeRange,
        'habitData': habitData,
        'healthData': healthData,
      });

      // Validate response data type before casting
      final responseData = result.data;
      if (responseData == null || responseData is! Map) {
        throw FormatException('Invalid health correlations response: expected Map, got ${responseData.runtimeType}');
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
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
