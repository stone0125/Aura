// =============================================================================
// badge_service.dart — App Icon Badge Service
// 应用图标角标服务
//
// Manages the app icon badge count on iOS. Shows the number of incomplete
// habits as the badge number. Delegates to NotificationService for the
// actual iOS badge update. Uses singleton pattern.
//
// 管理 iOS 上的应用图标角标数量。将未完成习惯的数量显示为角标数字。
// 委托 NotificationService 执行实际的 iOS 角标更新。使用单例模式。
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'dart:io';

/// Service to manage app icon badge count (iOS only via NotificationService)
class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  /// Factory constructor returning the singleton instance
  /// 工厂构造函数，返回单例实例
  factory BadgeService() => _instance;

  /// Private internal constructor for singleton pattern
  /// 单例模式的私有内部构造函数
  BadgeService._internal();

  bool _badgeEnabled = true;
  static const String _badgeEnabledKey = 'badge_enabled';
  int _lastBadgeCount = 0;
  bool _isSupported = false;

  /// Initialize badge service
  /// 初始化角标服务
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _badgeEnabled = prefs.getBool(_badgeEnabledKey) ?? true;
    _isSupported = !kIsWeb && Platform.isIOS;
  }

  /// Get badge enabled state
  /// 获取角标启用状态
  bool get isEnabled => _badgeEnabled;

  /// Check if device supports badges
  /// 检查设备是否支持角标
  bool get isSupported => _isSupported;

  /// Set badge enabled/disabled
  /// 设置角标启用/禁用
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
  /// 更新角标数量
  Future<void> updateBadgeCount(int incompleteCount) async {
    // Ensure count is never negative
    final safeCount = incompleteCount < 0 ? 0 : incompleteCount;
    _lastBadgeCount = _badgeEnabled ? safeCount : 0;

    if (_badgeEnabled && !kIsWeb && Platform.isIOS) {
      // Delegate to NotificationService for iOS badges
      await NotificationService().setBadgeCount(_lastBadgeCount);
    }
  }

  /// Clear the badge
  /// 清除角标
  Future<void> clearBadge() async {
    _lastBadgeCount = 0;
    if (!kIsWeb && Platform.isIOS) {
      await NotificationService().setBadgeCount(0);
    }
  }

  /// Reset state on logout to prevent cross-user data leaks
  /// 登出时重置状态以防止跨用户数据泄漏
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
  /// 获取要显示的当前角标数量
  int get currentBadgeCount => _badgeEnabled ? _lastBadgeCount : 0;
}
