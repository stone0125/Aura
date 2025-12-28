import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/settings_models.dart';

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
    if (_userId == null) return;
    final doc = await _userDoc!.get();
    if (!doc.exists) {
      await _userDoc!.set({
        'email': _auth.currentUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      await _userDoc!.update({'lastLogin': FieldValue.serverTimestamp()});
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
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
          memberSince:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
    if (_userId == null) return;
    // Only allow updating own profile
    if (profile.id != _userId) return;

    await _userDoc!.set({
      'firstName': profile.firstName,
      'lastName': profile.lastName,
      'displayName': profile.displayName,
      'email': profile.email,
      'bio': profile.bio,
      'avatarUrl': profile.avatarUrl,
      'isPro': profile.isPro,
      // Don't overwrite createdAt if it exists, or handle merge
    }, SetOptions(merge: true));
  }

  Future<void> saveDeviceToken(String token) async {
    if (_userId == null) return;
    await _userDoc!.set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  // --- Habit Operations ---

  // Stream of habits
  Stream<List<Habit>> getHabits() {
    if (_habitsRef == null) return Stream.value([]);
    return _habitsRef!.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Parse reminder time if available
        TimeOfDay? reminderTime;
        if (data['reminderHour'] != null && data['reminderMinute'] != null) {
          reminderTime = TimeOfDay(
            hour: data['reminderHour'] as int,
            minute: data['reminderMinute'] as int,
          );
        }

        return Habit(
          id: doc.id,
          name: data['name'] ?? '',
          category: HabitCategory.values.firstWhere(
            (e) => e.name == data['category'],
            orElse: () => HabitCategory.health,
          ),
          streak: data['streak'] ?? 0,
          isCompleted: data['isCompleted'] ?? false,
          lastCompletedDate: data['lastCompletedDate'] != null
              ? (data['lastCompletedDate'] as Timestamp).toDate()
              : null,
          reminderEnabled: data['reminderEnabled'] ?? false,
          reminderTime: reminderTime,
        );
      }).toList();
    });
  }

  // Add Habit
  Future<void> addHabit(Habit habit) async {
    if (_habitsRef == null) return;
    await _habitsRef!.doc(habit.id).set({
      'name': habit.name,
      'category': habit.category.name,
      'streak': habit.streak,
      'isCompleted': habit.isCompleted,
      'lastCompletedDate': habit.lastCompletedDate != null
          ? Timestamp.fromDate(habit.lastCompletedDate!)
          : null,
      'reminderEnabled': habit.reminderEnabled,
      'reminderHour': habit.reminderTime?.hour,
      'reminderMinute': habit.reminderTime?.minute,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Habit
  Future<void> updateHabit(Habit habit) async {
    if (_habitsRef == null) return;
    await _habitsRef!.doc(habit.id).update({
      'name': habit.name,
      'category': habit.category.name,
      'streak': habit.streak,
      'isCompleted': habit.isCompleted,
      'lastCompletedDate': habit.lastCompletedDate != null
          ? Timestamp.fromDate(habit.lastCompletedDate!)
          : null,
      'reminderEnabled': habit.reminderEnabled,
      'reminderHour': habit.reminderTime?.hour,
      'reminderMinute': habit.reminderTime?.minute,
    });
  }

  // Delete Habit
  Future<void> deleteHabit(String habitId) async {
    if (_habitsRef == null) return;
    await _habitsRef!.doc(habitId).delete();
  }

  // --- History Operations ---

  // Log a completion
  Future<void> logCompletion(String habitId, DateTime date) async {
    if (_habitsRef == null) return;

    // Use date as ID to ensure uniqueness per day (YYYY-MM-DD)
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    await _habitsRef!.doc(habitId).collection('history').doc(dateStr).set({
      'completedAt': Timestamp.fromDate(date),
    });
  }

  // Remove a completion (undo)
  Future<void> removeCompletion(String habitId, DateTime date) async {
    if (_habitsRef == null) return;

    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    await _habitsRef!.doc(habitId).collection('history').doc(dateStr).delete();
  }

  // Get history
  Future<List<DateTime>> getHabitHistory(String habitId) async {
    if (_habitsRef == null) return [];

    try {
      final snapshot = await _habitsRef!
          .doc(habitId)
          .collection('history')
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return (data['completedAt'] as Timestamp).toDate();
      }).toList();
    } catch (e) {
      debugPrint("Error fetching history: $e");
      return [];
    }
  }

  // Toggle Completion
  Future<void> toggleHabitCompletion(Habit habit) async {
    final updatedHabit = habit.toggleCompletion();
    await updateHabit(updatedHabit);

    // Update history
    if (updatedHabit.isCompleted) {
      await logCompletion(habit.id, DateTime.now());
    } else {
      // If unclompleting today, remove today's log
      await removeCompletion(habit.id, DateTime.now());
    }
  }
}
