// =============================================================================
// firestore_service.dart — Firestore Database Service
// Firestore 数据库服务
//
// Handles all CRUD operations with Cloud Firestore (NoSQL database):
// - User management (create, read, update profiles)
// - Habit operations (add, update, delete, real-time stream)
// - Completion history (log, remove, query)
// - AI scores and daily reviews storage
// - Health correlations storage
// - Account deletion (batch delete all subcollections)
// Data structure: users/{userId}/habits/{habitId}/history/{dateId}
//
// 处理与 Cloud Firestore（NoSQL 数据库）的所有增删改查操作：
// - 用户管理（创建、读取、更新资料）
// - 习惯操作（添加、更新、删除、实时流）
// - 完成历史（记录、移除、查询）
// - AI 评分和每日回顾存储
// - 健康关联分析存储
// - 账户删除（批量删除所有子集合）
// 数据结构：users/{userId}/habits/{habitId}/history/{dateId}
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/settings_models.dart';
import '../models/ai_scoring_models.dart';
import '../models/daily_review_models.dart';
import '../models/health_data_models.dart';
import '../utils/date_utils.dart' as date_utils;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current authenticated user's ID
  /// 获取当前已认证用户的 ID
  String? get _userId => _auth.currentUser?.uid;

  /// Reference to the users collection
  /// 用户集合的引用
  CollectionReference get _usersRef => _db.collection('users');

  /// Reference to the current user's document
  /// 当前用户文档的引用
  DocumentReference? get _userDoc =>
      _userId != null ? _usersRef.doc(_userId) : null;

  /// Reference to the current user's habits subcollection
  /// 当前用户习惯子集合的引用
  CollectionReference? get _habitsRef => _userDoc?.collection('habits');

  // --- User Operations ---

  /// Create user document in Firestore if it does not already exist
  /// 如果用户文档不存在则在 Firestore 中创建
  Future<void> createUserIfNotExists() async {
    final userDoc = _userDoc;
    if (_userId == null || userDoc == null) return;
    final doc = await userDoc.get();
    if (!doc.exists) {
      await userDoc.set({
        'email': _auth.currentUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        if (kDebugMode) 'tierOverride': 'mastery',
      });
    } else {
      await userDoc.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'tierOverride': kDebugMode ? 'mastery' : FieldValue.delete(),
      });
    }
  }

  /// Fetch the user profile for the given user ID (own profile only)
  /// 获取指定用户 ID 的用户资料（仅限自己的资料）
  Future<UserProfile?> getUserProfile(String userId) async {
    // Security: Only allow fetching own profile
    if (userId != _userId) {
      debugPrint('Security: Rejected getUserProfile for unauthorized userId');
      return null;
    }

    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        // Check if profile data exists within the user doc
        // Assuming profile data is stored at the root of user doc or in a 'profile' field
        // Let's assume root for simplicity but handle existing fields
        return UserProfile(
          id: userId,
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          email: data['email'] ?? '',
          displayName: data['displayName'] ?? '',
          bio: data['bio'] ?? '',
          avatarUrl: data['avatarUrl'],
          memberSince: data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          isPro: data['isPro'] ?? false,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Update the user profile in Firestore (own profile only)
  /// 更新 Firestore 中的用户资料（仅限自己的资料）
  Future<void> updateUserProfile(UserProfile profile) async {
    final userDoc = _userDoc;
    if (_userId == null || userDoc == null) return;
    // Only allow updating own profile
    if (profile.id != _userId) return;

    await userDoc.set({
      'firstName': profile.firstName,
      'lastName': profile.lastName,
      'displayName': profile.displayName,
      'email': profile.email,
      'bio': profile.bio,
      'avatarUrl': profile.avatarUrl,
      // isPro is managed server-side via RevenueCat sync; don't write from client
      // Don't overwrite createdAt if it exists, or handle merge
    }, SetOptions(merge: true));
  }

  /// Save FCM device token to the user document
  /// 将 FCM 设备令牌保存到用户文档
  Future<void> saveDeviceToken(String token) async {
    final userDoc = _userDoc;
    if (_userId == null || userDoc == null) return;
    await userDoc.set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Save notification preferences for daily summary
  /// 保存每日摘要的通知偏好设置
  Future<void> saveNotificationPreferences({
    required bool enabled,
    required int hour,
    required int minute,
    required String timezone,
  }) async {
    final userDoc = _userDoc;
    if (_userId == null || userDoc == null) return;
    await userDoc.set({
      'notificationPrefs': {
        'dailySummaryEnabled': enabled,
        'dailySummaryHour': hour,
        'dailySummaryMinute': minute,
        'timezone': timezone,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
    debugPrint(
      'Saved notification prefs: $hour:$minute ($timezone), enabled: $enabled',
    );
  }

  /// Get notification preferences
  /// 获取通知偏好设置
  Future<Map<String, dynamic>?> getNotificationPreferences() async {
    final userDoc = _userDoc;
    if (_userId == null || userDoc == null) return null;
    try {
      final doc = await userDoc.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final rawPrefs = data['notificationPrefs'];
        if (rawPrefs is Map) {
          return Map<String, dynamic>.from(rawPrefs);
        }
        return null;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting notification prefs: $e');
      return null;
    }
  }

  // --- Habit Operations ---

  /// Stream real-time list of habits from Firestore
  /// 从 Firestore 实时流式获取习惯列表
  Stream<List<Habit>> getHabits() {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return Stream.value([]);
    return habitsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Parse reminder time if available (with type-safe conversion and bounds checking)
        TimeOfDay? reminderTime;
        if (data['reminderHour'] != null && data['reminderMinute'] != null) {
          final hour = (data['reminderHour'] as num?)?.toInt();
          final minute = (data['reminderMinute'] as num?)?.toInt();
          // Validate bounds: hour must be 0-23, minute must be 0-59
          if (hour != null &&
              minute != null &&
              hour >= 0 &&
              hour <= 23 &&
              minute >= 0 &&
              minute <= 59) {
            reminderTime = TimeOfDay(hour: hour, minute: minute);
          }
        }

        // Check if habit was completed TODAY (not just any day)
        final lastCompletedDate = data['lastCompletedDate'] is Timestamp
            ? (data['lastCompletedDate'] as Timestamp).toDate()
            : null;
        final isCompletedToday = _isCompletedToday(lastCompletedDate);

        // Parse createdAt (nullable for backward compat with existing docs)
        final createdAt = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : null;

        // Calculate effective streak
        // If not completed today AND not completed yesterday, streak is broken -> 0
        int effectiveStreak = data['streak'] ?? 0;
        if (!isCompletedToday && !_wasCompletedYesterday(lastCompletedDate)) {
          effectiveStreak = 0;
        }

        return Habit(
          id: doc.id,
          name: data['name'] ?? '',
          category: HabitCategory.values.firstWhere(
            (e) => e.name == data['category'],
            orElse: () => HabitCategory.health,
          ),
          streak: effectiveStreak,
          isCompleted: isCompletedToday,
          lastCompletedDate: lastCompletedDate,
          goalType: data['goalType'] as String? ?? 'none',
          goalValue: (data['goalValue'] as num?)?.toInt(),
          goalUnit: data['goalUnit'] as String?,
          reminderEnabled: data['reminderEnabled'] ?? false,
          reminderTime: reminderTime,
          createdAt: createdAt,
        );
      }).toList();
    });
  }

  /// Check if the given date is today
  /// 检查给定日期是否为今天
  bool _isCompletedToday(DateTime? lastCompletedDate) {
    if (lastCompletedDate == null) return false;
    return date_utils.isToday(lastCompletedDate.toLocal());
  }

  /// Add a new habit to Firestore
  /// 向 Firestore 添加新习惯
  Future<void> addHabit(Habit habit) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return;
    await habitsRef.doc(habit.id).set({
      'name': habit.name,
      'category': habit.category.name,
      'streak': habit.streak,
      'isCompleted': habit.isCompleted,
      'lastCompletedDate': habit.lastCompletedDate != null
          ? Timestamp.fromDate(habit.lastCompletedDate!)
          : null,
      'goalType': habit.goalType,
      'goalValue': habit.goalValue,
      'goalUnit': habit.goalUnit,
      'reminderEnabled': habit.reminderEnabled,
      'reminderHour': habit.reminderTime?.hour,
      'reminderMinute': habit.reminderTime?.minute,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing habit in Firestore
  /// 更新 Firestore 中已有的习惯
  Future<void> updateHabit(Habit habit) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return;
    await habitsRef.doc(habit.id).update({
      'name': habit.name,
      'category': habit.category.name,
      'streak': habit.streak,
      'isCompleted': habit.isCompleted,
      'lastCompletedDate': habit.lastCompletedDate != null
          ? Timestamp.fromDate(habit.lastCompletedDate!)
          : null,
      'goalType': habit.goalType,
      'goalValue': habit.goalValue,
      'goalUnit': habit.goalUnit,
      'reminderEnabled': habit.reminderEnabled,
      'reminderHour': habit.reminderTime?.hour,
      'reminderMinute': habit.reminderTime?.minute,
    });
  }

  /// Delete a habit and its history subcollection from Firestore
  /// 从 Firestore 删除习惯及其历史子集合
  Future<void> deleteHabit(String habitId) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return;

    // Collect all document references to delete
    final List<DocumentReference> toDelete = [];

    // Delete history subcollection docs first (Firestore doesn't cascade-delete)
    final historySnapshot = await habitsRef
        .doc(habitId)
        .collection('history')
        .get();
    for (final doc in historySnapshot.docs) {
      toDelete.add(doc.reference);
    }
    toDelete.add(habitsRef.doc(habitId));

    // Chunk into batches of 400 (Firestore limit is 500 per batch)
    for (var i = 0; i < toDelete.length; i += 400) {
      final batch = _db.batch();
      final end = (i + 400).clamp(0, toDelete.length);
      for (var j = i; j < end; j++) {
        batch.delete(toDelete[j]);
      }
      await batch.commit();
    }
  }

  // --- History Operations ---

  /// Log a habit completion for a specific date
  /// 记录特定日期的习惯完成情况
  Future<void> logCompletion(String habitId, DateTime date) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return;

    // Use date as ID to ensure uniqueness per day (YYYY-MM-DD)
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    await habitsRef.doc(habitId).collection('history').doc(dateStr).set({
      'completedAt': Timestamp.fromDate(date),
    });
  }

  /// Remove a habit completion record (undo)
  /// 移除习惯完成记录（撤销）
  Future<void> removeCompletion(String habitId, DateTime date) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return;

    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    await habitsRef.doc(habitId).collection('history').doc(dateStr).delete();
  }

  /// Get completion history for a habit (limited to N days for performance)
  /// 获取习惯的完成历史（为提升性能限制天数）
  Future<List<DateTime>> getHabitHistory(
    String habitId, {
    int limitDays = 90,
  }) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return [];

    try {
      // Limit query to recent history for performance
      final snapshot = await habitsRef
          .doc(habitId)
          .collection('history')
          .orderBy('completedAt', descending: true)
          .limit(limitDays)
          .get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            final ts = data['completedAt'];
            if (ts is! Timestamp) return null;
            return ts.toDate();
          })
          .whereType<DateTime>()
          .toList();
    } catch (e) {
      debugPrint('Error fetching history: $e');
      return [];
    }
  }

  /// Toggle habit completion status using an atomic batch write
  /// 使用原子批量写入切换习惯完成状态
  Future<void> toggleHabitCompletion(Habit habit) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return;

    // Check if already completed TODAY (not based on stored isCompleted)
    final isCompletedToday = _isCompletedToday(habit.lastCompletedDate);

    // Determine new state
    final willBeCompleted = !isCompletedToday;

    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Calculate new streak and lastCompletedDate
    int newStreak = habit.streak;
    DateTime? newLastCompletedDate;

    if (willBeCompleted) {
      // Completing: set lastCompletedDate to now
      newLastCompletedDate = now;
      if (_wasCompletedYesterday(habit.lastCompletedDate)) {
        newStreak = habit.streak + 1;
      } else {
        newStreak = 1;
      }
    } else {
      // Undoing: find the most recent completion before today
      final previousCompletions = await habitsRef
          .doc(habit.id)
          .collection('history')
          .where(FieldPath.documentId, isLessThan: dateStr)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(1)
          .get();

      if (previousCompletions.docs.isNotEmpty) {
        final data = previousCompletions.docs.first.data();
        final ts = data['completedAt'];
        if (ts is Timestamp) {
          newLastCompletedDate = ts.toDate();
        }
      }
      // If no previous completion, newLastCompletedDate stays null

      if (habit.streak > 0) {
        newStreak = habit.streak - 1;
      }
    }

    // Atomic batch: update habit + history in one write
    final batch = _db.batch();
    batch.update(habitsRef.doc(habit.id), {
      'name': habit.name,
      'category': habit.category.name,
      'streak': newStreak,
      'isCompleted': willBeCompleted,
      'lastCompletedDate': newLastCompletedDate != null
          ? Timestamp.fromDate(newLastCompletedDate)
          : null,
      'reminderEnabled': habit.reminderEnabled,
      'reminderHour': habit.reminderTime?.hour,
      'reminderMinute': habit.reminderTime?.minute,
    });

    if (willBeCompleted) {
      batch.set(habitsRef.doc(habit.id).collection('history').doc(dateStr), {
        'completedAt': Timestamp.fromDate(now),
      });
    } else {
      batch.delete(habitsRef.doc(habit.id).collection('history').doc(dateStr));
    }

    await batch.commit();
  }

  /// Check if habit was completed yesterday (explicit year/month/day comparison to avoid midnight edge cases)
  /// 检查习惯是否在昨天完成（显式比较年/月/日以避免午夜边界问题）
  bool _wasCompletedYesterday(DateTime? lastCompletedDate) {
    if (lastCompletedDate == null) return false;
    return date_utils.isYesterday(lastCompletedDate.toLocal());
  }

  // --- AI Scoring Operations ---

  /// Collection reference for daily reviews
  /// 每日回顾集合的引用
  CollectionReference? get _dailyReviewsRef =>
      _userDoc?.collection('dailyReviews');

  /// Collection reference for habit scores
  /// 习惯评分集合的引用
  CollectionReference? get _habitScoresRef =>
      _userDoc?.collection('habitScores');

  /// Collection reference for health correlations
  /// 健康关联分析集合的引用
  CollectionReference? get _healthCorrelationsRef =>
      _userDoc?.collection('healthCorrelations');

  /// Save a daily review
  /// 保存每日回顾
  Future<void> saveDailyReview(DailyReview review) async {
    final dailyReviewsRef = _dailyReviewsRef;
    if (dailyReviewsRef == null) return;

    await dailyReviewsRef.doc(review.date).set({
      ...review.toJson(),
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get daily review for a specific date
  /// 获取指定日期的每日回顾
  Future<DailyReview?> getDailyReview(String date) async {
    final dailyReviewsRef = _dailyReviewsRef;
    if (dailyReviewsRef == null) return null;

    try {
      final doc = await dailyReviewsRef.doc(date).get();
      if (doc.exists && doc.data() != null) {
        return DailyReview.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting daily review: $e');
      return null;
    }
  }

  /// Get daily review history for a date range
  /// 获取指定日期范围内的每日回顾历史
  Future<List<DailyReview>> getDailyReviewHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    final dailyReviewsRef = _dailyReviewsRef;
    if (dailyReviewsRef == null) return [];

    try {
      Query query = dailyReviewsRef.orderBy('date', descending: true);

      if (startDate != null) {
        final startStr =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        query = query.where('date', isGreaterThanOrEqualTo: startStr);
      }

      if (endDate != null) {
        final endStr =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        query = query.where('date', isLessThanOrEqualTo: endStr);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        return DailyReview.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error getting daily review history: $e');
      return [];
    }
  }

  /// Save a habit score
  /// 保存习惯评分
  Future<void> saveHabitScore(HabitScore score) async {
    final habitScoresRef = _habitScoresRef;
    if (habitScoresRef == null) return;

    await habitScoresRef.doc(score.habitId).set({
      ...score.toJson(),
      'savedAt': FieldValue.serverTimestamp(),
    });

    // Also save to history subcollection
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    await habitScoresRef
        .doc(score.habitId)
        .collection('history')
        .doc(dateStr)
        .set({
          'date': dateStr,
          'score': score.overallScore,
          'grade': score.grade,
          'savedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Get latest habit score
  /// 获取最新的习惯评分
  Future<HabitScore?> getHabitScore(String habitId) async {
    final habitScoresRef = _habitScoresRef;
    if (habitScoresRef == null) return null;

    try {
      final doc = await habitScoresRef.doc(habitId).get();
      if (doc.exists && doc.data() != null) {
        return HabitScore.fromJson(
          doc.data() as Map<String, dynamic>,
          habitId: habitId,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting habit score: $e');
      return null;
    }
  }

  /// Get habit score history
  /// 获取习惯评分历史
  Future<List<ScoreHistoryEntry>> getScoreHistory(
    String habitId, {
    int limit = 30,
  }) async {
    final habitScoresRef = _habitScoresRef;
    if (habitScoresRef == null) return [];

    try {
      final snapshot = await habitScoresRef
          .doc(habitId)
          .collection('history')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return ScoreHistoryEntry.fromJson(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error getting score history: $e');
      return [];
    }
  }

  /// Get all habit scores for the user (limited to 100 for performance)
  /// 获取用户的所有习惯评分（为提升性能限制 100 条）
  Future<Map<String, HabitScore>> getAllHabitScores() async {
    final habitScoresRef = _habitScoresRef;
    if (habitScoresRef == null) return {};

    try {
      // Add limit to prevent unbounded results
      final snapshot = await habitScoresRef.limit(100).get();
      final scores = <String, HabitScore>{};

      for (final doc in snapshot.docs) {
        scores[doc.id] = HabitScore.fromJson(
          doc.data() as Map<String, dynamic>,
          habitId: doc.id,
        );
      }

      return scores;
    } catch (e) {
      debugPrint('Error getting all habit scores: $e');
      return {};
    }
  }

  /// Save health correlation analysis
  /// 保存健康关联分析
  Future<void> saveHealthCorrelation(HealthCorrelationAnalysis analysis) async {
    final healthCorrelationsRef = _healthCorrelationsRef;
    if (healthCorrelationsRef == null) return;

    final id = '${analysis.timeRange}_${DateTime.now().millisecondsSinceEpoch}';
    await healthCorrelationsRef.doc(id).set({
      ...analysis.toJson(),
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get latest health correlation analysis
  /// 获取最新的健康关联分析
  Future<HealthCorrelationAnalysis?> getLatestHealthCorrelation() async {
    final healthCorrelationsRef = _healthCorrelationsRef;
    if (healthCorrelationsRef == null) return null;

    try {
      final snapshot = await healthCorrelationsRef
          .orderBy('savedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return HealthCorrelationAnalysis.fromJson(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting health correlation: $e');
      return null;
    }
  }

  /// Get completion history for the last N days (for AI scoring)
  /// 获取最近 N 天的完成历史（用于 AI 评分）
  /// Optimized to use a single query instead of N+1 individual document fetches
  /// 优化为使用单次查询替代 N+1 次单独文档读取
  Future<List<bool>> getCompletionHistoryForScoring(
    String habitId, {
    int days = 30,
  }) async {
    final safeDays = days.clamp(1, 365);
    final habitsRef = _habitsRef;
    if (habitsRef == null) return [];

    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: safeDays - 1));

      // Format date strings for range query
      final startDateStr =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Single query to get all completion documents in the date range
      final snapshot = await habitsRef
          .doc(habitId)
          .collection('history')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDateStr)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endDateStr)
          .get();

      // Build a set of completed date strings for O(1) lookup
      final completedDates = snapshot.docs.map((doc) => doc.id).toSet();

      // Build history list from oldest to newest
      final history = <bool>[];
      for (int i = safeDays - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        history.add(completedDates.contains(dateStr));
      }

      return history;
    } catch (e) {
      debugPrint('Error getting completion history for scoring: $e');
      return [];
    }
  }

  /// Save health integration enabled preference
  /// 保存健康集成启用偏好设置
  Future<void> saveHealthIntegrationEnabled(bool enabled) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    await userDoc.set({
      'healthIntegrationEnabled': enabled,
      'healthIntegrationUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get health integration enabled preference
  /// 获取健康集成启用偏好设置
  Future<bool> getHealthIntegrationEnabled() async {
    final userDoc = _userDoc;
    if (userDoc == null) return false;

    try {
      final doc = await userDoc.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['healthIntegrationEnabled'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error getting health integration status: $e');
      return false;
    }
  }

  // --- Account Deletion ---

  /// Delete all user data from Firestore (subcollections + user doc).
  /// 从 Firestore 删除所有用户数据（子集合 + 用户文档）。
  /// Subcollection counts are bounded, so client-side batch deletes are safe.
  /// 子集合数量有限，因此客户端批量删除是安全的。
  /// Accepts an optional [forUserId] to delete data for a specific user
  /// (needed when auth user is already deleted).
  Future<void> deleteAllUserData({String? forUserId}) async {
    final userId = forUserId ?? _userId;
    if (userId == null) return;
    final userDoc = _usersRef.doc(userId);

    final List<DocumentReference> toDelete = [];

    // Collect all document references to delete
    final subcollections = [
      'habits',
      'dailyReviews',
      'habitScores',
      'usageCounters',
      'healthCorrelations',
    ];

    for (final sub in subcollections) {
      final snapshot = await userDoc.collection(sub).get();
      for (final doc in snapshot.docs) {
        // For habits and habitScores, also delete their nested history subcollection
        if (sub == 'habits' || sub == 'habitScores') {
          final historySnapshot = await doc.reference
              .collection('history')
              .get();
          for (final histDoc in historySnapshot.docs) {
            toDelete.add(histDoc.reference);
          }
        }
        toDelete.add(doc.reference);
      }
    }

    // Delete the user document itself
    toDelete.add(userDoc);

    // Chunk into batches of 400 (Firestore limit is 500 per batch)
    for (var i = 0; i < toDelete.length; i += 400) {
      final batch = _db.batch();
      final end = (i + 400).clamp(0, toDelete.length);
      for (var j = i; j < end; j++) {
        batch.delete(toDelete[j]);
      }
      await batch.commit();
    }
  }
}
