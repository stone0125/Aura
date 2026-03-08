// =============================================================================
// analytics_service.dart — Firebase Analytics Service
// Firebase 分析服务
//
// Tracks user events and behaviour for product insights:
// - Habit events (created, completed)
// - Export and share events
// - AI Coach interaction events
// - Reminder configuration events
// - User properties (habit count, best streak, pro status)
//
// 追踪用户事件和行为以获取产品洞察：
// - 习惯事件（创建、完成）
// - 导出和分享事件
// - AI 教练交互事件
// - 提醒配置事件
// - 用户属性（习惯数量、最佳连续记录、专业版状态）
// =============================================================================

import 'package:firebase_analytics/firebase_analytics.dart';

/// Service for tracking analytics events
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  /// Factory constructor returning the singleton instance
  /// 工厂构造函数，返回单例实例
  factory AnalyticsService() => _instance;

  /// Private internal constructor for singleton pattern
  /// 单例模式的私有内部构造函数
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get the observer for navigation tracking
  /// 获取用于导航追踪的观察者
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ==================== Habit Events ====================

  /// Track habit creation
  /// 追踪习惯创建事件
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
  /// 追踪习惯完成事件
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
  /// 追踪数据导出事件
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
  /// 追踪成就分享事件
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
  /// 追踪进度分享事件
  Future<void> logProgressShared() async {
    await _analytics.logEvent(name: 'progress_shared');
  }

  /// Track streak milestone shared
  /// 追踪连续记录里程碑分享事件
  Future<void> logStreakMilestoneShared({required int streakDays}) async {
    await _analytics.logEvent(
      name: 'streak_milestone_shared',
      parameters: {'streak_days': streakDays},
    );
  }

  // ==================== Reminder Events ====================

  /// Track reminder enabled
  /// 追踪提醒启用事件
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
  /// 追踪 AI 教练页面查看事件
  Future<void> logAICoachViewed({
    required String tab, // 'suggestions', 'insights', 'tips'
  }) async {
    await _analytics.logEvent(
      name: 'ai_coach_viewed',
      parameters: {'tab': tab},
    );
  }

  /// Track AI suggestion accepted
  /// 追踪 AI 建议被接受事件
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
  /// 追踪 AI 建议被忽略事件
  Future<void> logAISuggestionDismissed({required String suggestionId}) async {
    await _analytics.logEvent(
      name: 'ai_suggestion_dismissed',
      parameters: {'suggestion_id': suggestionId},
    );
  }

  // ==================== Screen Time Events ====================

  /// Track session start
  /// 追踪会话开始事件
  Future<void> logSessionStart() async {
    await _analytics.logEvent(name: 'session_start');
  }

  /// Track screen view (automatic with observer, but can be manual too)
  /// 追踪页面查看事件（可通过观察者自动追踪，也可手动调用）
  Future<void> logScreenView({required String screenName}) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // ==================== User Properties ====================

  /// Set user's total habit count
  /// 设置用户的习惯总数
  Future<void> setUserHabitCount(int count) async {
    await _analytics.setUserProperty(
      name: 'total_habits',
      value: count.toString(),
    );
  }

  /// Set user's best streak
  /// 设置用户的最佳连续记录
  Future<void> setUserBestStreak(int streak) async {
    await _analytics.setUserProperty(
      name: 'best_streak',
      value: streak.toString(),
    );
  }

  /// Set if user is pro subscriber
  /// 设置用户是否为专业版订阅者
  Future<void> setUserIsPro(bool isPro) async {
    await _analytics.setUserProperty(name: 'is_pro', value: isPro.toString());
  }
}
