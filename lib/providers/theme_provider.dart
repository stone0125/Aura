// =============================================================================
// theme_provider.dart — Theme Provider
// 主题 Provider
//
// Manages light/dark theme switching and persists the preference to
// SharedPreferences. Uses ChangeNotifier to rebuild the UI when theme changes.
//
// 管理亮色/暗色主题切换，并将偏好持久化到 SharedPreferences。
// 使用 ChangeNotifier 在主题更改时重建 UI。
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme (light/dark mode)
/// 管理应用主题（亮色/暗色模式）的 Provider
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themeModeKey = 'theme_mode';

  /// Constructor that loads the saved theme mode
  /// 构造函数，加载已保存的主题模式
  ThemeProvider() {
    _loadThemeMode();
  }

  /// Get current theme mode
  /// 获取当前主题模式
  ThemeMode get themeMode => _themeMode;

  /// Check if dark mode is enabled
  /// 检查暗色模式是否已启用
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Load saved theme mode from shared preferences
  /// 从 SharedPreferences 加载已保存的主题模式
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);
      if (savedMode != null) {
        _themeMode = savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, use default light mode
      debugPrint('Error loading theme mode: $e');
    }
  }

  /// Toggle between light and dark mode
  /// 在亮色和暗色模式之间切换
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _saveThemeMode();
  }

  /// Set specific theme mode
  /// 设置特定的主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      await _saveThemeMode();
    }
  }

  /// Clear user data on logout to prevent cross-user data leaks
  /// 登出时清除用户数据，防止跨用户数据泄漏
  Future<void> clearUserData() async {
    _themeMode = ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeModeKey);
    } catch (e) {
      debugPrint('Error clearing theme preference: $e');
    }
    notifyListeners();
  }

  /// Save theme mode to shared preferences
  /// 将主题模式保存到 SharedPreferences
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeModeKey,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }
}
