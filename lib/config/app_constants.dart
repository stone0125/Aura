/// App-wide constants and configuration values
class AppConstants {
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
