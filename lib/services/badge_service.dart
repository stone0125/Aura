import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'dart:io';

/// Service to manage app icon badge count (iOS only via NotificationService)
class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  bool _badgeEnabled = true;
  static const String _badgeEnabledKey = 'badge_enabled';
  int _lastBadgeCount = 0;
  bool _isSupported = false;

  /// Initialize badge service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _badgeEnabled = prefs.getBool(_badgeEnabledKey) ?? true;
    _isSupported = Platform.isIOS;
  }

  /// Get badge enabled state
  bool get isEnabled => _badgeEnabled;

  /// Check if device supports badges
  bool get isSupported => _isSupported;

  /// Set badge enabled/disabled
  Future<void> setBadgeEnabled(bool enabled) async {
    _badgeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_badgeEnabledKey, enabled);

    if (!enabled) {
      await clearBadge();
    }
    debugPrint('Badge enabled: $enabled');
  }

  /// Update badge count
  Future<void> updateBadgeCount(int incompleteCount) async {
    // Ensure count is never negative
    final safeCount = incompleteCount < 0 ? 0 : incompleteCount;
    _lastBadgeCount = _badgeEnabled ? safeCount : 0;

    if (_badgeEnabled && Platform.isIOS) {
      // Delegate to NotificationService for iOS badges
      await NotificationService().setBadgeCount(_lastBadgeCount);
    }
  }

  /// Clear the badge
  Future<void> clearBadge() async {
    _lastBadgeCount = 0;
    if (Platform.isIOS) {
      await NotificationService().setBadgeCount(0);
    }
  }

  /// Reset state on logout to prevent cross-user data leaks
  Future<void> resetOnLogout() async {
    _lastBadgeCount = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_badgeEnabledKey);
    } catch (e) {
      debugPrint('Error clearing badge preference: $e');
    }
  }

  /// Get current badge count to show
  int get currentBadgeCount => _badgeEnabled ? _lastBadgeCount : 0;
}
