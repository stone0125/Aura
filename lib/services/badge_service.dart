import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'notification_service.dart';

/// Service to manage app icon badge count
class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  bool _badgeEnabled = true;
  static const String _badgeEnabledKey = 'badge_enabled';
  int _lastBadgeCount = 0;

  /// Initialize badge service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _badgeEnabled = prefs.getBool(_badgeEnabledKey) ?? true;
  }

  /// Get badge enabled state
  bool get isEnabled => _badgeEnabled;

  /// Set badge enabled/disabled
  Future<void> setBadgeEnabled(bool enabled) async {
    _badgeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_badgeEnabledKey, enabled);

    if (!enabled) {
      _lastBadgeCount = 0;
      // Clear badge on iOS when disabled
      if (Platform.isIOS) {
        await NotificationService().clearBadge();
      }
    }
    debugPrint('Badge enabled: $enabled');
  }

  /// Update badge count
  Future<void> updateBadgeCount(int incompleteCount) async {
    _lastBadgeCount = _badgeEnabled ? incompleteCount : 0;

    // Update iOS badge
    if (Platform.isIOS && _badgeEnabled) {
      await NotificationService().setBadgeCount(_lastBadgeCount);
    }

    debugPrint(
      'Badge count updated: $_lastBadgeCount (enabled: $_badgeEnabled)',
    );
  }

  /// Clear the badge
  Future<void> clearBadge() async {
    _lastBadgeCount = 0;
    if (Platform.isIOS) {
      await NotificationService().clearBadge();
    }
  }

  /// Get current badge count to show
  int get currentBadgeCount => _badgeEnabled ? _lastBadgeCount : 0;
}
