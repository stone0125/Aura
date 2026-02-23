import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/badge_service.dart';
import '../services/notification_service.dart';
import '../services/subscription_service.dart';
import '../models/settings_models.dart';

/// Provider for managing app settings and user profile
class SettingsProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<User?>? _authSubscription;
  UserProfile _userProfile = UserProfile(
    id: '',
    firstName: '',
    lastName: '',
    email: '',
    displayName: '',
    bio: '',
    avatarUrl: null,
    memberSince: DateTime.now(),
    isPro: false,
  );

  AppSettings _settings = const AppSettings();
  bool _isInitializing = false;

  SettingsProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // Link Firebase user to RevenueCat
        SubscriptionService().loginUser(user.uid);
        initialize();
      } else {
        // Reset RevenueCat to anonymous (also clears usage quotas)
        SubscriptionService().logoutUser();
        // Reset singleton service state
        BadgeService().resetOnLogout();
        NotificationService().resetOnLogout();
        // Reset settings to defaults
        _settings = const AppSettings();
        // Clear user-specific SharedPreferences
        _clearUserPreferences();
        // Clear user profile on logout
        _userProfile = UserProfile(
          id: '',
          firstName: '',
          lastName: '',
          email: '',
          displayName: '',
          bio: '',
          avatarUrl: null,
          memberSince: DateTime.now(),
          isPro: false,
        );
        notifyListeners();
      }
    });
  }

  /// Clear user-specific SharedPreferences keys on logout
  Future<void> _clearUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notificationsEnabled');
      await prefs.remove('defaultReminderHour');
      await prefs.remove('defaultReminderMinute');
      await prefs.remove('badgeEnabled');
      await prefs.remove('motivationalMessages');
      await prefs.remove('aiSuggestionsEnabled');
      await prefs.remove('aiOptimizedReminders');
      await prefs.remove('shareDataForAI');
      await prefs.remove('themePreference');
    } catch (e) {
      debugPrint('Error clearing user preferences: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Getters
  UserProfile get userProfile => _userProfile;
  AppSettings get settings => _settings;

  /// Initialize settings and load user profile
  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
    // Load saved settings from SharedPreferences
    await _loadFromStorage();

    // Load real user data if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload(); // Ensure we have latest data
        final freshUser = FirebaseAuth.instance.currentUser;
        if (freshUser == null) {
          debugPrint("DEBUG: User became null after reload");
          notifyListeners();
          return;
        }
        debugPrint("DEBUG: SettingsProvider init - Auth User loaded");

        final userDoc = await _firestoreService.getUserProfile(freshUser.uid);

        if (userDoc != null) {
          debugPrint("DEBUG: Firestore Profile found");
          _userProfile = userDoc;

          // Self-heal: If firestore name OR email is missing but auth has it, update it
          bool needsUpdate = false;
          UserProfile updatedProfile = _userProfile;

          if ((updatedProfile.firstName.isEmpty ||
                  updatedProfile.firstName == 'User') &&
              freshUser.displayName != null &&
              freshUser.displayName!.isNotEmpty) {
            debugPrint("DEBUG: Fixing empty DB name with Auth data");
            final names = freshUser.displayName!.split(' ');
            updatedProfile = updatedProfile.copyWith(
              firstName: names.first,
              lastName: names.length > 1 ? names.sublist(1).join(' ') : '',
              displayName: freshUser.displayName,
            );
            needsUpdate = true;
          }

          if (updatedProfile.email.isEmpty &&
              freshUser.email != null &&
              freshUser.email!.isNotEmpty) {
            debugPrint("DEBUG: Fixing empty DB email with Auth data");
            updatedProfile = updatedProfile.copyWith(email: freshUser.email);
            needsUpdate = true;
          }

          if (needsUpdate) {
            _userProfile = updatedProfile;
            await _firestoreService.updateUserProfile(updatedProfile);
          }
        } else {
          debugPrint("DEBUG: No Firestore doc found, creating new.");
          // Fallback if doc doesn't exist yet, create from Auth
          final names = freshUser.displayName?.split(' ') ?? ['User'];
          String firstName = names.first;
          String lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

          if (firstName.isEmpty) firstName = 'User';

          _userProfile = UserProfile(
            id: freshUser.uid,
            firstName: firstName,
            lastName: lastName,
            displayName: freshUser.displayName ?? 'User',
            email: freshUser.email ?? '',
            bio: 'Ready to build better habits!',
            avatarUrl: freshUser.photoURL,
            memberSince: freshUser.metadata.creationTime ?? DateTime.now(),
            isPro: false,
          );
          // Create in DB
          await _firestoreService.updateUserProfile(_userProfile);
        }
      } catch (e) {
        debugPrint('Error loading user profile: $e');
      }
    } else {
      debugPrint("DEBUG: SettingsProvider init - No user logged in");
    }
    notifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  // ==================== Profile Methods ====================

  /// Update user profile
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final nameChanged = firstName != null || lastName != null;

    _userProfile = UserProfile(
      id: _userProfile.id,
      firstName: firstName ?? _userProfile.firstName,
      lastName: lastName ?? _userProfile.lastName,
      email: _userProfile.email,
      displayName: displayName ?? _userProfile.displayName,
      bio: bio ?? _userProfile.bio,
      // Clear auto-imported avatar when name changes, so computed initials show
      avatarUrl: avatarUrl ?? (nameChanged ? null : _userProfile.avatarUrl),
      memberSince: _userProfile.memberSince,
      isPro: _userProfile.isPro,
    );
    notifyListeners();

    if (_userProfile.id.isNotEmpty) {
      await _firestoreService.updateUserProfile(_userProfile);
    }

    // Sync displayName to Firebase Auth so it stays consistent
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && nameChanged) {
      final newDisplayName = _userProfile.fullName.trim();
      if (newDisplayName.isNotEmpty) {
        try {
          await user.updateDisplayName(newDisplayName);
        } catch (e) {
          debugPrint('Error updating Auth displayName: $e');
        }
      }
    }
  }

  /// Upgrade to Pro — presents the RevenueCat paywall
  Future<void> upgradeToPro() async {
    final subscriptionService = SubscriptionService();
    await subscriptionService.presentPaywall();

    // Update profile based on actual subscription status
    final isPro = subscriptionService.isPro;
    _userProfile = _userProfile.copyWith(isPro: isPro);
    notifyListeners();
    if (isPro) {
      _saveToStorage();
    }
  }

  // ==================== Appearance Methods ====================

  /// Change theme preference
  void setThemePreference(ThemePreference preference) {
    _settings = _settings.copyWith(themePreference: preference);
    notifyListeners();
    _saveToStorage();
  }

  // ==================== Notification Methods ====================

  /// Toggle notifications
  void setNotificationsEnabled(bool enabled) {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Set default reminder time
  void setDefaultReminderTime(TimeOfDay time) {
    _settings = _settings.copyWith(defaultReminderTime: time);
    notifyListeners();
    _saveToStorage();
  }

  /// Change notification sound
  void setNotificationSound(String sound) {
    _settings = _settings.copyWith(notificationSound: sound);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle badge
  void setBadgeEnabled(bool enabled) {
    _settings = _settings.copyWith(badgeEnabled: enabled);
    BadgeService().setBadgeEnabled(enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle motivational messages
  void setMotivationalMessages(bool enabled) {
    _settings = _settings.copyWith(motivationalMessages: enabled);
    notifyListeners();
    _saveToStorage();
  }

  // ==================== AI Preferences Methods ====================

  /// Toggle AI suggestions
  void setAISuggestionsEnabled(bool enabled) {
    _settings = _settings.copyWith(aiSuggestionsEnabled: enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Set suggestion frequency
  void setSuggestionFrequency(NotificationFrequency frequency) {
    _settings = _settings.copyWith(suggestionFrequency: frequency);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle AI optimized reminders
  void setAIOptimizedReminders(bool enabled) {
    _settings = _settings.copyWith(aiOptimizedReminders: enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle share data for AI
  void setShareDataForAI(bool enabled) {
    _settings = _settings.copyWith(shareDataForAI: enabled);
    notifyListeners();
    _saveToStorage();
  }

  // ==================== Data & Sync Methods ====================

  /// Toggle cloud sync
  Future<void> setCloudSyncEnabled(bool enabled) async {
    if (enabled) {
      // Simulate enabling sync
      _settings = _settings.copyWith(
        cloudSyncEnabled: true,
        syncStatus: SyncStatus.syncing,
      );
      notifyListeners();

      // Simulate sync completion
      await Future.delayed(const Duration(seconds: 2));
      _settings = _settings.copyWith(
        syncStatus: SyncStatus.synced,
        lastSyncTime: DateTime.now(),
      );
    } else {
      _settings = _settings.copyWith(
        cloudSyncEnabled: false,
        syncStatus: SyncStatus.offline,
      );
    }
    notifyListeners();
    _saveToStorage();
  }

  /// Manually trigger sync
  Future<void> syncNow() async {
    if (!_settings.cloudSyncEnabled) return;

    _settings = _settings.copyWith(syncStatus: SyncStatus.syncing);
    notifyListeners();

    // Simulate sync
    await Future.delayed(const Duration(seconds: 2));

    _settings = _settings.copyWith(
      syncStatus: SyncStatus.synced,
      lastSyncTime: DateTime.now(),
    );
    notifyListeners();
  }

  /// Toggle auto backup
  void setAutoBackupEnabled(bool enabled) {
    _settings = _settings.copyWith(autoBackupEnabled: enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Export data
  Future<void> exportData(ExportFormat format) async {
    // Simulate export process
    await Future.delayed(const Duration(seconds: 1));
    // In real app, this would generate and share the file
  }

  /// Import data
  Future<bool> importData() async {
    // Simulate import process
    await Future.delayed(const Duration(seconds: 1));
    // In real app, this would parse and merge data
    return true;
  }

  /// Clear all habit data (keep settings)
  Future<void> clearAllData() async {
    // Simulate clearing data
    await Future.delayed(const Duration(milliseconds: 500));
    // In real app, this would clear all habits from database
    notifyListeners();
  }

  // ==================== Account Methods ====================

  /// Change email
  Future<bool> changeEmail(String newEmail) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would verify and update email
    return true;
  }

  /// Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would verify current password and update
    return true;
  }

  /// Sign out
  Future<void> signOut() async {
    await AuthService().signOut();
    notifyListeners();
  }

  /// Delete account — deletes Firebase Auth account first (may throw
  /// requires-recent-login), then removes Firestore data and signs out.
  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Delete the Firebase Auth account FIRST
    //    This may throw requires-recent-login if the session is stale.
    //    By deleting auth first, user data is preserved on failure so
    //    the user can re-authenticate and retry.
    await user.delete();

    // 2. Delete all Firestore user data (subcollections + user doc)
    await _firestoreService.deleteAllUserData();

    // 3. Sign out (clears local state)
    await AuthService().signOut();
    notifyListeners();
  }

  // ==================== Accessibility Methods ====================

  /// Set text size
  void setTextSize(TextSizePreference size) {
    _settings = _settings.copyWith(textSize: size);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle reduce motion
  void setReduceMotion(bool enabled) {
    _settings = _settings.copyWith(reduceMotion: enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle color blind mode
  void setColorBlindMode(bool enabled) {
    _settings = _settings.copyWith(colorBlindMode: enabled);
    notifyListeners();
    _saveToStorage();
  }

  // ==================== Help & Support Methods ====================

  /// Open FAQ
  void openFAQ() {
    // In real app, would navigate to FAQ screen or open web page
  }

  /// Open tutorials
  void openTutorials() {
    // In real app, would navigate to tutorials screen
  }

  /// Contact support
  Future<void> contactSupport(String message) async {
    // Simulate sending support request
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would send email or create support ticket
  }

  /// Report bug
  Future<void> reportBug(String description) async {
    // Simulate bug report
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would send bug report with logs
  }

  /// Request feature
  Future<void> requestFeature(String description) async {
    // Simulate feature request
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would submit feature request
  }

  /// Open AI transparency info
  void openAITransparency() {
    // In real app, would navigate to detailed AI transparency screen
  }

  // ==================== Storage ====================

  /// Save settings to persistent storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        'notificationsEnabled',
        _settings.notificationsEnabled,
      );
      await prefs.setInt(
        'defaultReminderHour',
        _settings.defaultReminderTime.hour,
      );
      await prefs.setInt(
        'defaultReminderMinute',
        _settings.defaultReminderTime.minute,
      );
      await prefs.setBool('badgeEnabled', _settings.badgeEnabled);
      await prefs.setBool(
        'motivationalMessages',
        _settings.motivationalMessages,
      );
      await prefs.setBool(
        'aiSuggestionsEnabled',
        _settings.aiSuggestionsEnabled,
      );
      await prefs.setBool(
        'aiOptimizedReminders',
        _settings.aiOptimizedReminders,
      );
      await prefs.setBool('shareDataForAI', _settings.shareDataForAI);
      await prefs.setString('themePreference', _settings.themePreference.name);
      debugPrint('Settings saved to storage');
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  /// Load settings from persistent storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final notificationsEnabled =
          prefs.getBool('notificationsEnabled') ?? true;
      final reminderHour = (prefs.getInt('defaultReminderHour') ?? 9).clamp(0, 23);
      final reminderMinute = (prefs.getInt('defaultReminderMinute') ?? 0).clamp(0, 59);
      final badgeEnabled = prefs.getBool('badgeEnabled') ?? true;
      final motivationalMessages =
          prefs.getBool('motivationalMessages') ?? true;
      final aiSuggestionsEnabled =
          prefs.getBool('aiSuggestionsEnabled') ?? true;
      final aiOptimizedReminders =
          prefs.getBool('aiOptimizedReminders') ?? false;
      final shareDataForAI = prefs.getBool('shareDataForAI') ?? true;
      final themeName = prefs.getString('themePreference') ?? 'system';

      ThemePreference themePreference = ThemePreference.system;
      try {
        themePreference = ThemePreference.values.firstWhere(
          (e) => e.name == themeName,
        );
      } catch (_) {}

      _settings = _settings.copyWith(
        notificationsEnabled: notificationsEnabled,
        defaultReminderTime: TimeOfDay(
          hour: reminderHour,
          minute: reminderMinute,
        ),
        badgeEnabled: badgeEnabled,
        motivationalMessages: motivationalMessages,
        aiSuggestionsEnabled: aiSuggestionsEnabled,
        aiOptimizedReminders: aiOptimizedReminders,
        shareDataForAI: shareDataForAI,
        themePreference: themePreference,
      );

      debugPrint(
        'Settings loaded from storage: reminder time = $reminderHour:$reminderMinute',
      );
      // Note: notifyListeners removed here - called once in initialize() after _loadFromStorage completes
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }
}
