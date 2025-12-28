import 'package:firebase_analytics/firebase_analytics.dart';

/// Service for tracking analytics events
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get the observer for navigation tracking
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ==================== Habit Events ====================

  /// Track habit creation
  Future<void> logHabitCreated({
    required String category,
    required bool hasReminder,
    bool isAISuggested = false,
  }) async {
    await _analytics.logEvent(
      name: 'habit_created',
      parameters: {
        'category': category,
        'has_reminder': hasReminder,
        'is_ai_suggested': isAISuggested,
      },
    );
  }

  /// Track habit completion
  Future<void> logHabitCompleted({
    required String habitId,
    required String category,
    required int currentStreak,
  }) async {
    await _analytics.logEvent(
      name: 'habit_completed',
      parameters: {
        'habit_id': habitId,
        'category': category,
        'current_streak': currentStreak,
      },
    );
  }

  // ==================== Export Events ====================

  /// Track data export
  Future<void> logDataExported({
    required String format, // 'csv' or 'json'
    required int habitCount,
  }) async {
    await _analytics.logEvent(
      name: 'data_exported',
      parameters: {'format': format, 'habit_count': habitCount},
    );
  }

  // ==================== Share Events ====================

  /// Track achievement shared
  Future<void> logAchievementShared({
    required String achievementId,
    required bool isUnlocked,
  }) async {
    await _analytics.logEvent(
      name: 'achievement_shared',
      parameters: {'achievement_id': achievementId, 'is_unlocked': isUnlocked},
    );
  }

  /// Track progress shared
  Future<void> logProgressShared() async {
    await _analytics.logEvent(name: 'progress_shared');
  }

  /// Track streak milestone shared
  Future<void> logStreakMilestoneShared({required int streakDays}) async {
    await _analytics.logEvent(
      name: 'streak_milestone_shared',
      parameters: {'streak_days': streakDays},
    );
  }

  // ==================== Reminder Events ====================

  /// Track reminder enabled
  Future<void> logReminderEnabled({
    required int hour,
    required int minute,
  }) async {
    await _analytics.logEvent(
      name: 'reminder_enabled',
      parameters: {
        'hour': hour,
        'minute': minute,
        'time_period': hour < 12
            ? 'morning'
            : (hour < 18 ? 'afternoon' : 'evening'),
      },
    );
  }

  // ==================== AI Coach Events ====================

  /// Track AI Coach screen viewed
  Future<void> logAICoachViewed({
    required String tab, // 'suggestions', 'insights', 'tips'
  }) async {
    await _analytics.logEvent(
      name: 'ai_coach_viewed',
      parameters: {'tab': tab},
    );
  }

  /// Track AI suggestion accepted
  Future<void> logAISuggestionAccepted({
    required String suggestionId,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'ai_suggestion_accepted',
      parameters: {'suggestion_id': suggestionId, 'category': category},
    );
  }

  /// Track AI suggestion dismissed
  Future<void> logAISuggestionDismissed({required String suggestionId}) async {
    await _analytics.logEvent(
      name: 'ai_suggestion_dismissed',
      parameters: {'suggestion_id': suggestionId},
    );
  }

  // ==================== Screen Time Events ====================

  /// Track session start
  Future<void> logSessionStart() async {
    await _analytics.logEvent(name: 'session_start');
  }

  /// Track screen view (automatic with observer, but can be manual too)
  Future<void> logScreenView({required String screenName}) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // ==================== User Properties ====================

  /// Set user's total habit count
  Future<void> setUserHabitCount(int count) async {
    await _analytics.setUserProperty(
      name: 'total_habits',
      value: count.toString(),
    );
  }

  /// Set user's best streak
  Future<void> setUserBestStreak(int streak) async {
    await _analytics.setUserProperty(
      name: 'best_streak',
      value: streak.toString(),
    );
  }

  /// Set if user is pro subscriber
  Future<void> setUserIsPro(bool isPro) async {
    await _analytics.setUserProperty(name: 'is_pro', value: isPro.toString());
  }
}
