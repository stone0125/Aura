import 'package:flutter/material.dart';
import '../models/settings_models.dart';

/// Provider for managing app settings and user profile
class SettingsProvider with ChangeNotifier {
  UserProfile _userProfile = UserProfile(
    id: 'user_001',
    firstName: 'Sarah',
    lastName: 'Mitchell',
    email: 'sarah.mitchell@email.com',
    displayName: 'Sarah M.',
    bio: 'Building better habits, one day at a time. Computer Science student passionate about self-improvement.',
    avatarUrl: null, // Can be set to actual URL
    memberSince: DateTime.now().subtract(const Duration(days: 90)),
    isPro: false,
  );

  AppSettings _settings = const AppSettings();

  // Getters
  UserProfile get userProfile => _userProfile;
  AppSettings get settings => _settings;

  /// Initialize settings (load from SharedPreferences in real app)
  Future<void> initialize() async {
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 300));
    notifyListeners();
  }

  // ==================== Profile Methods ====================

  /// Update user profile
  void updateProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) {
    _userProfile = _userProfile.copyWith(
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
    );
    notifyListeners();
    _saveToStorage();
  }

  /// Upgrade to Pro
  Future<void> upgradeToPro() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    _userProfile = _userProfile.copyWith(isPro: true);
    notifyListeners();
    _saveToStorage();
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
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would verify current password and update
    return true;
  }

  /// Sign out
  Future<void> signOut() async {
    // Simulate sign out
    await Future.delayed(const Duration(milliseconds: 500));
    // In real app, would clear auth tokens and navigate to login
  }

  /// Delete account
  Future<void> deleteAccount() async {
    // Simulate account deletion
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would delete all user data and account
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
    // In real app, would use SharedPreferences
    // await prefs.setBool('notificationsEnabled', _settings.notificationsEnabled);
    // await prefs.setString('themePreference', _settings.themePreference.name);
    // etc.
  }
}
