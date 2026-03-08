// =============================================================================
// settings_provider.dart — Settings & User Profile Provider
// 设置与用户资料 Provider
//
// Manages user profile (name, email, avatar), app settings (notifications,
// theme, AI preferences), and account operations (sign out, delete account).
// Persists settings to SharedPreferences and syncs profile to Firestore.
//
// 管理用户资料（姓名、邮箱、头像）、应用设置（通知、主题、AI 偏好）
// 和账户操作（登出、删除账户）。将设置持久化到 SharedPreferences，
// 并将资料同步到 Firestore。
// =============================================================================

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
/// 管理应用设置和用户资料的 Provider
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

  /// Constructor that sets up authentication state listener
  /// 构造函数，设置身份验证状态监听器
  SettingsProvider() {
    _initAuthListener();
  }

  /// Initialize Firebase auth state listener to handle login/logout
  /// 初始化 Firebase 身份验证状态监听器以处理登录/登出
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
  /// 登出时清除用户相关的 SharedPreferences 键
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

  /// Dispose resources and cancel auth subscription
  /// 释放资源并取消身份验证订阅
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Get the current user profile
  /// 获取当前用户资料
  UserProfile get userProfile => _userProfile;

  /// Get the current app settings
  /// 获取当前应用设置
  AppSettings get settings => _settings;

  /// Initialize settings and load user profile
  /// 初始化设置并加载用户资料
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
  /// 更新用户资料
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
  /// 升级到 Pro — 展示 RevenueCat 付费墙
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
  /// 更改主题偏好
  void setThemePreference(ThemePreference preference) {
    _settings = _settings.copyWith(themePreference: preference);
    notifyListeners();
    _saveToStorage();
  }

  // ==================== Notification Methods ====================

  /// Toggle notifications
  /// 切换通知开关
  void setNotificationsEnabled(bool enabled) {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Set default reminder time
  /// 设置默认提醒时间
  void setDefaultReminderTime(TimeOfDay time) {
    _settings = _settings.copyWith(defaultReminderTime: time);
    notifyListeners();
    _saveToStorage();
  }

  /// Change notification sound
  /// 更改通知声音
  void setNotificationSound(String sound) {
    _settings = _settings.copyWith(notificationSound: sound);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle badge
  /// 切换徽章开关
  void setBadgeEnabled(bool enabled) {
    _settings = _settings.copyWith(badgeEnabled: enabled);
    BadgeService().setBadgeEnabled(enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle motivational messages
  /// 切换激励消息开关
  void setMotivationalMessages(bool enabled) {
    _settings = _settings.copyWith(motivationalMessages: enabled);
    notifyListeners();
    _saveToStorage();
  }

  // ==================== AI Preferences Methods ====================

  /// Toggle AI suggestions
  /// 切换 AI 建议开关
  void setAISuggestionsEnabled(bool enabled) {
    _settings = _settings.copyWith(aiSuggestionsEnabled: enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Set suggestion frequency
  /// 设置建议频率
  void setSuggestionFrequency(NotificationFrequency frequency) {
    _settings = _settings.copyWith(suggestionFrequency: frequency);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle AI optimized reminders
  /// 切换 AI 优化提醒开关
  void setAIOptimizedReminders(bool enabled) {
    _settings = _settings.copyWith(aiOptimizedReminders: enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle share data for AI
  /// 切换为 AI 共享数据的开关
  void setShareDataForAI(bool enabled) {
    _settings = _settings.copyWith(shareDataForAI: enabled);
    notifyListeners();
    _saveToStorage();
  }

  // ==================== Data & Sync Methods ====================

  /// Toggle cloud sync
  /// 切换云同步开关
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
  /// 手动触发同步
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
  /// 切换自动备份开关
  void setAutoBackupEnabled(bool enabled) {
    _settings = _settings.copyWith(autoBackupEnabled: enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Export data
  /// 导出数据
  Future<void> exportData(ExportFormat format) async {
    // Simulate export process
    await Future.delayed(const Duration(seconds: 1));
    // In real app, this would generate and share the file
  }

  /// Import data
  /// 导入数据
  Future<bool> importData() async {
    // Simulate import process
    await Future.delayed(const Duration(seconds: 1));
    // In real app, this would parse and merge data
    return true;
  }

  /// Clear all habit data (keep settings)
  /// 清除所有习惯数据（保留设置）
  Future<void> clearAllData() async {
    // Simulate clearing data
    await Future.delayed(const Duration(milliseconds: 500));
    // In real app, this would clear all habits from database
    notifyListeners();
  }

  // ==================== Account Methods ====================

  /// Change email
  /// 更改邮箱
  Future<bool> changeEmail(String newEmail) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would verify and update email
    return true;
  }

  /// Change password
  /// 更改密码
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
  /// 登出
  Future<void> signOut() async {
    await AuthService().signOut();
    notifyListeners();
  }

  /// Delete account — deletes Firebase Auth account first, then Firestore data
  /// 删除账户 — 先删除 Firebase Auth 账户，然后删除 Firestore 数据
  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Delete the Firebase Auth account FIRST
    //    This may throw requires-recent-login if the session is stale.
    //    By doing this first, we avoid deleting Firestore data only to have
    //    auth deletion fail (leaving the user with an account but no data).
    await user.delete();

    // 2. Delete all Firestore user data (pass userId since auth user is gone)
    await _firestoreService.deleteAllUserData(forUserId: user.uid);

    // 3. Sign out (clears local state)
    await AuthService().signOut();
    notifyListeners();
  }

  // ==================== Accessibility Methods ====================

  /// Set text size
  /// 设置文字大小
  void setTextSize(TextSizePreference size) {
    _settings = _settings.copyWith(textSize: size);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle reduce motion
  /// 切换减少动画开关
  void setReduceMotion(bool enabled) {
    _settings = _settings.copyWith(reduceMotion: enabled);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle color blind mode
  /// 切换色盲模式开关
  void setColorBlindMode(bool enabled) {
    _settings = _settings.copyWith(colorBlindMode: enabled);
    notifyListeners();
    _saveToStorage();
  }

  // ==================== Help & Support Methods ====================

  /// Open FAQ
  /// 打开常见问题
  void openFAQ() {
    // In real app, would navigate to FAQ screen or open web page
  }

  /// Open tutorials
  /// 打开教程
  void openTutorials() {
    // In real app, would navigate to tutorials screen
  }

  /// Contact support
  /// 联系客服
  Future<void> contactSupport(String message) async {
    // Simulate sending support request
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would send email or create support ticket
  }

  /// Report bug
  /// 报告缺陷
  Future<void> reportBug(String description) async {
    // Simulate bug report
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would send bug report with logs
  }

  /// Request feature
  /// 提交功能请求
  Future<void> requestFeature(String description) async {
    // Simulate feature request
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would submit feature request
  }

  /// Open AI transparency info
  /// 打开 AI 透明度信息
  void openAITransparency() {
    // In real app, would navigate to detailed AI transparency screen
  }

  // ==================== Storage ====================

  /// Save settings to persistent storage
  /// 将设置保存到持久化存储
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
  /// 从持久化存储加载设置
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
