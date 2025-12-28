/// App-wide constants and configuration values
class AppConstants {
  AppConstants._();

  /// Minimum number of days of tracking required before AI insights are available
  static const int minDaysForAIInsights = 7;

  /// App name
  static const String appName = 'Aura';

  /// App version
  static const String appVersion = '1.0.0';

  /// Support email addresses
  static const String supportEmail = 'support@habittracker.app';
  static const String bugsEmail = 'bugs@habittracker.app';
  static const String featuresEmail = 'features@habittracker.app';

  /// External URLs (update these when you have real ones)
  static const String faqUrl = 'https://habittracker.app/faq';
  static const String tutorialsUrl = 'https://habittracker.app/tutorials';
  static const String aiTransparencyUrl =
      'https://habittracker.app/ai-transparency';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.aura.habittracker';
  static const String appStoreUrl = 'https://apps.apple.com/app/id123456789';
}
