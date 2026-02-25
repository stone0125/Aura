import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/settings_models.dart';
import '../models/ai_scoring_models.dart';
import '../models/daily_review_models.dart';
import '../models/health_data_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Collection References
  CollectionReference get _usersRef => _db.collection('users');

  DocumentReference? get _userDoc =>
      _userId != null ? _usersRef.doc(_userId) : null;

  CollectionReference? get _habitsRef => _userDoc?.collection('habits');

  // --- User Operations ---

  Future<void> createUserIfNotExists() async {
    final userDoc = _userDoc;
    if (_userId == null || userDoc == null) return;
    final doc = await userDoc.get();
    if (!doc.exists) {
      await userDoc.set({
        'email': _auth.currentUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});
    }
  }

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

  Future<void> saveDeviceToken(String token) async {
    final userDoc = _userDoc;
    if (_userId == null || userDoc == null) return;
    await userDoc.set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Save notification preferences for daily summary
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

  // Stream of habits
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
          if (hour != null && minute != null &&
              hour >= 0 && hour <= 23 &&
              minute >= 0 && minute <= 59) {
            reminderTime = TimeOfDay(
              hour: hour,
              minute: minute,
            );
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
  bool _isCompletedToday(DateTime? lastCompletedDate) {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    final localDate = lastCompletedDate.toLocal();
    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }

  // Add Habit
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

  // Update Habit
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

  // Delete Habit (including history subcollection)
  Future<void> deleteHabit(String habitId) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return;

    // Collect all document references to delete
    final List<DocumentReference> toDelete = [];

    // Delete history subcollection docs first (Firestore doesn't cascade-delete)
    final historySnapshot =
        await habitsRef.doc(habitId).collection('history').get();
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

  // Log a completion
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

  // Remove a completion (undo)
  Future<void> removeCompletion(String habitId, DateTime date) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return;

    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    await habitsRef.doc(habitId).collection('history').doc(dateStr).delete();
  }

  // Get history (limited to 90 days for performance)
  Future<List<DateTime>> getHabitHistory(String habitId, {int limitDays = 90}) async {
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
      debugPrint("Error fetching history: $e");
      return [];
    }
  }

  // Toggle Completion (atomic batch write)
  Future<void> toggleHabitCompletion(Habit habit) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return;

    // Check if already completed TODAY (not based on stored isCompleted)
    final isCompletedToday = _isCompletedToday(habit.lastCompletedDate);

    // Determine new state
    final willBeCompleted = !isCompletedToday;

    // Calculate new streak (check if streak should continue or reset)
    int newStreak = habit.streak;
    if (willBeCompleted) {
      // Check if streak should continue (completed yesterday) or reset to 1
      if (_wasCompletedYesterday(habit.lastCompletedDate)) {
        // Streak continues - add 1
        newStreak = habit.streak + 1;
      } else {
        // Streak broken (skipped days) - reset to 1
        newStreak = 1;
      }
    } else if (habit.streak > 0) {
      newStreak = habit.streak - 1;
    }

    // Create updated habit
    final updatedHabit = habit.copyWith(
      isCompleted: willBeCompleted,
      streak: newStreak,
      lastCompletedDate: willBeCompleted ? DateTime.now() : null,
      clearLastCompletedDate: !willBeCompleted,
    );

    // Atomic batch: update habit + history in one write
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final batch = _db.batch();
    batch.update(habitsRef.doc(habit.id), {
      'name': updatedHabit.name,
      'category': updatedHabit.category.name,
      'streak': updatedHabit.streak,
      'isCompleted': updatedHabit.isCompleted,
      'lastCompletedDate': updatedHabit.lastCompletedDate != null
          ? Timestamp.fromDate(updatedHabit.lastCompletedDate!)
          : null,
      'reminderEnabled': updatedHabit.reminderEnabled,
      'reminderHour': updatedHabit.reminderTime?.hour,
      'reminderMinute': updatedHabit.reminderTime?.minute,
    });

    if (willBeCompleted) {
      batch.set(
        habitsRef.doc(habit.id).collection('history').doc(dateStr),
        {'completedAt': Timestamp.fromDate(now)},
      );
    } else {
      batch.delete(
        habitsRef.doc(habit.id).collection('history').doc(dateStr),
      );
    }

    await batch.commit();
  }

  /// Check if habit was completed yesterday
  bool _wasCompletedYesterday(DateTime? lastCompletedDate) {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final localDate = lastCompletedDate.toLocal();
    return localDate.year == yesterday.year &&
        localDate.month == yesterday.month &&
        localDate.day == yesterday.day;
  }

  // --- AI Scoring Operations ---

  /// Collection reference for daily reviews
  CollectionReference? get _dailyReviewsRef =>
      _userDoc?.collection('dailyReviews');

  /// Collection reference for habit scores
  CollectionReference? get _habitScoresRef =>
      _userDoc?.collection('habitScores');

  /// Collection reference for health correlations
  CollectionReference? get _healthCorrelationsRef =>
      _userDoc?.collection('healthCorrelations');

  /// Save a daily review
  Future<void> saveDailyReview(DailyReview review) async {
    final dailyReviewsRef = _dailyReviewsRef;
    if (dailyReviewsRef == null) return;

    await dailyReviewsRef.doc(review.date).set({
      ...review.toJson(),
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get daily review for a specific date
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
  Future<void> saveHealthCorrelation(HealthCorrelationAnalysis analysis) async {
    final healthCorrelationsRef = _healthCorrelationsRef;
    if (healthCorrelationsRef == null) return;

    final id =
        '${analysis.timeRange}_${DateTime.now().millisecondsSinceEpoch}';
    await healthCorrelationsRef.doc(id).set({
      ...analysis.toJson(),
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get latest health correlation analysis
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
  /// Optimized to use a single query instead of N+1 individual document fetches
  Future<List<bool>> getCompletionHistoryForScoring(
    String habitId, {
    int days = 30,
  }) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return [];

    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days - 1));

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
      for (int i = days - 1; i >= 0; i--) {
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
  Future<void> saveHealthIntegrationEnabled(bool enabled) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    await userDoc.set({
      'healthIntegrationEnabled': enabled,
      'healthIntegrationUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get health integration enabled preference
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
  /// Subcollection counts are bounded, so client-side batch deletes are safe.
  Future<void> deleteAllUserData() async {
    final userId = _userId;
    final userDoc = _userDoc;
    if (userId == null || userDoc == null) return;

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
          final historySnapshot =
              await doc.reference.collection('history').get();
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
