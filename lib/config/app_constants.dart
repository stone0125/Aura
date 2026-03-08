// =============================================================================
// app_constants.dart — App-Wide Constants
// 应用级常量
//
// Defines global constants used across the app (app name, version, etc.).
// 定义应用中使用的全局常量（应用名称、版本等）。
// =============================================================================

/// App-wide constants and configuration values
/// 应用级常量和配置值
class AppConstants {
  /// Private constructor to prevent instantiation
  /// 私有构造函数，防止实例化
  AppConstants._();

  /// Minimum number of days of tracking required before AI insights are available
  static const int minDaysForAIInsights = 7;

  /// App name
  static const String appName = 'Aura';

  /// App version
  static const String appVersion = '1.0.1';

  /// Support email addresses
  static const String supportEmail = 'xiaostone0125@gmail.com';
  static const String bugsEmail = 'xiaostone0125@gmail.com';
  static const String featuresEmail = 'xiaostone0125@gmail.com';

  /// External URLs
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.aura.habittracker';
  // TODO: Replace placeholder App Store ID before iOS release
  static const String appStoreUrl = 'https://apps.apple.com/app/idPLACEHOLDER';
}
