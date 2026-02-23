import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/subscription_models.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // ============================================================
  // MOCK MODE - Set to false to use real RevenueCat API
  // ============================================================
  static const bool _useMockMode = false;

  // RevenueCat API Keys via --dart-define
  // Run with: flutter run --dart-define=RC_ANDROID_KEY=goog_xxxxx
  static const _apiKeyAndroid = String.fromEnvironment('RC_ANDROID_KEY', defaultValue: '');
  static const _apiKeyIOS = String.fromEnvironment('RC_IOS_KEY', defaultValue: '');

  // Entitlement IDs in RevenueCat dashboard
  static const _entitlementGrowth = 'growth';
  static const _entitlementMastery = 'mastery';

  // Storage keys
  static const _keyAISuggestionsUsed = 'ai_suggestions_used_today';
  static const _keyLastSuggestionDate = 'last_suggestion_date';
  static const _keyAIReportsUsed = 'ai_reports_used_this_month';
  static const _keyLastReportDate = 'last_report_date';

  SubscriptionTier _currentTier = SubscriptionTier.starter;
  int _aiSuggestionsUsedToday = 0;
  DateTime? _lastSuggestionDate;
  int _aiReportsUsedThisMonth = 0;
  DateTime? _lastReportDate;

  // Getters
  SubscriptionTier get currentTier => _currentTier;
  bool get isPro =>
      _currentTier == SubscriptionTier.growth ||
      _currentTier == SubscriptionTier.mastery;

  /// Get current subscription limits
  SubscriptionLimits getLimits(int currentHabitCount) {
    return SubscriptionLimits(
      tier: _currentTier,
      currentHabitCount: currentHabitCount,
      aiSuggestionsUsedToday: _aiSuggestionsUsedToday,
      lastSuggestionDate: _lastSuggestionDate,
      aiReportsUsedThisMonth: _aiReportsUsedThisMonth,
      lastReportDate: _lastReportDate,
    );
  }

  /// Check if user can add more habits
  bool canAddHabit(int currentHabitCount) {
    return getLimits(currentHabitCount).canAddHabit;
  }

  /// Check if user can use AI suggestions
  bool canUseAISuggestion() {
    return getLimits(0).canUseAISuggestion;
  }

  /// Record usage of an AI suggestion
  Future<void> recordAISuggestionUsage() async {
    final now = DateTime.now();

    // Check if it's a new day
    if (_lastSuggestionDate != null) {
      final isSameDay =
          _lastSuggestionDate!.year == now.year &&
          _lastSuggestionDate!.month == now.month &&
          _lastSuggestionDate!.day == now.day;
      if (!isSameDay) {
        _aiSuggestionsUsedToday = 0; // Reset for new day
      }
    }

    _aiSuggestionsUsedToday++;
    _lastSuggestionDate = now;
    await _saveUsageToStorage();
  }

  /// Get remaining AI suggestions for today
  int getRemainingAISuggestions() {
    return getLimits(0).remainingAISuggestions;
  }

  /// Check if user can use AI reports this month
  bool canUseAIReport() {
    return getLimits(0).canUseAIReport;
  }

  /// Record usage of an AI report
  Future<void> recordAIReportUsage() async {
    final now = DateTime.now();

    // Check if it's a new month
    if (_lastReportDate != null) {
      final isSameMonth =
          _lastReportDate!.year == now.year &&
          _lastReportDate!.month == now.month;
      if (!isSameMonth) {
        _aiReportsUsedThisMonth = 0; // Reset for new month
      }
    }

    _aiReportsUsedThisMonth++;
    _lastReportDate = now;
    await _saveUsageToStorage();
  }

  /// Get remaining AI reports for this month
  int getRemainingAIReports() {
    return getLimits(0).remainingAIReports;
  }

  Future<void> initialize() async {
    await _loadUsageFromStorage();

    if (_useMockMode) {
      debugPrint(
        '[RevenueCat] Initialized (mock mode) - Tier: ${_currentTier.displayName}',
      );
      _currentTier = SubscriptionTier.starter;
      return;
    }

    // Bypass all limits in debug mode for development
    if (kDebugMode) {
      debugPrint('[RevenueCat] Debug mode — using Mastery tier (unlimited)');
      _currentTier = SubscriptionTier.mastery;
      return;
    }

    // --- Real RevenueCat initialization ---
    final apiKey = Platform.isAndroid ? _apiKeyAndroid : _apiKeyIOS;
    if (apiKey.isEmpty) {
      debugPrint('[RevenueCat] WARNING: No API key provided. '
          'Run with --dart-define=RC_ANDROID_KEY=goog_xxxxx or RC_IOS_KEY=appl_xxxxx. '
          'Falling back to Starter tier.');
      _currentTier = SubscriptionTier.starter;
      return;
    }

    try {
      debugPrint('[RevenueCat] Configuring with ${Platform.isAndroid ? "Android" : "iOS"} key...');
      await Purchases.setLogLevel(LogLevel.debug);

      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      debugPrint('[RevenueCat] Configuration successful');

      await _checkSubscriptionStatus();

      // Listen for subscription changes
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        debugPrint('[RevenueCat] Customer info updated via listener');
        _updateTierFromCustomerInfo(customerInfo);
      });
    } catch (e) {
      debugPrint('[RevenueCat] Error initializing: $e');
      _currentTier = SubscriptionTier.starter;
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    if (_useMockMode) {
      return;
    }

    try {
      debugPrint('[RevenueCat] Checking subscription status...');
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateTierFromCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('[RevenueCat] Error checking subscription status: $e');
      _currentTier = SubscriptionTier.starter;
    }
  }

  void _updateTierFromCustomerInfo(CustomerInfo customerInfo) {
    final activeEntitlements = customerInfo.entitlements.all.entries
        .where((e) => e.value.isActive)
        .map((e) => e.key)
        .toList();
    debugPrint('[RevenueCat] Active entitlements: $activeEntitlements');

    // Check entitlements in order of highest to lowest
    if (customerInfo.entitlements.all[_entitlementMastery]?.isActive ?? false) {
      _currentTier = SubscriptionTier.mastery;
    } else if (customerInfo.entitlements.all[_entitlementGrowth]?.isActive ??
        false) {
      _currentTier = SubscriptionTier.growth;
    } else {
      _currentTier = SubscriptionTier.starter;
    }
    debugPrint('[RevenueCat] Tier resolved to: ${_currentTier.displayName}');
  }

  /// Present the RevenueCat Paywall
  Future<void> presentPaywall({Offering? offering}) async {
    if (_useMockMode) {
      debugPrint('[RevenueCat] Paywall presentation skipped (mock mode)');
      return;
    }

    try {
      debugPrint('[RevenueCat] Presenting paywall...');
      await RevenueCatUI.presentPaywall(
        offering: offering,
        displayCloseButton: true,
      );

      // Re-check status after paywall closes
      debugPrint('[RevenueCat] Paywall closed, re-checking status...');
      await _checkSubscriptionStatus();
    } catch (e) {
      debugPrint('[RevenueCat] Error presenting paywall: $e');
    }
  }

  /// Present the Customer Center for subscription management
  Future<void> presentCustomerCenter() async {
    if (_useMockMode) {
      debugPrint('[RevenueCat] Customer center skipped (mock mode)');
      return;
    }

    try {
      debugPrint('[RevenueCat] Presenting customer center...');
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('[RevenueCat] Error presenting customer center: $e');
    }
  }

  Future<List<Package>> getOfferings() async {
    if (_useMockMode) {
      return [];
    }

    try {
      debugPrint('[RevenueCat] Fetching offerings...');
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        final packages = offerings.current!.availablePackages;
        debugPrint('[RevenueCat] Found ${packages.length} packages in current offering');
        return packages;
      }
      debugPrint('[RevenueCat] No current offering available');
    } catch (e) {
      debugPrint('[RevenueCat] Error fetching offerings: $e');
    }
    return [];
  }

  Future<bool> purchasePackage(Package package) async {
    if (_useMockMode) {
      debugPrint('[RevenueCat] Purchase simulated (mock mode)');
      return true;
    }

    try {
      debugPrint('[RevenueCat] Purchasing package: ${package.identifier}...');
      PurchaseResult purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      _updateTierFromCustomerInfo(purchaseResult.customerInfo);
      debugPrint('[RevenueCat] Purchase complete, isPro: $isPro');
      return isPro;
    } catch (e) {
      debugPrint('[RevenueCat] Error purchasing package: $e');
      return false;
    }
  }

  /// Returns true if an active subscription was found and restored.
  Future<bool> restorePurchases() async {
    if (_useMockMode) {
      debugPrint('[RevenueCat] Restore purchases simulated (mock mode)');
      return false;
    }

    try {
      debugPrint('[RevenueCat] Restoring purchases...');
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      final previousTier = _currentTier;
      _updateTierFromCustomerInfo(customerInfo);
      final restored = _currentTier != previousTier && isPro;
      debugPrint('[RevenueCat] Restore complete, restored: $restored');
      return restored;
    } catch (e) {
      debugPrint('[RevenueCat] Error restoring purchases: $e');
      return false;
    }
  }

  // --- Firebase Auth ↔ RevenueCat User Linking ---

  /// Link a Firebase Auth user to RevenueCat
  Future<void> loginUser(String firebaseUserId) async {
    if (_useMockMode) {
      debugPrint('[RevenueCat] loginUser skipped (mock mode)');
      return;
    }
    if (_apiKeyAndroid.isEmpty && _apiKeyIOS.isEmpty) {
      debugPrint('[RevenueCat] loginUser skipped (no API key)');
      return;
    }

    try {
      debugPrint('[RevenueCat] Logging in user: $firebaseUserId');
      final result = await Purchases.logIn(firebaseUserId);
      debugPrint('[RevenueCat] Login successful, created: ${result.created}');
      _updateTierFromCustomerInfo(result.customerInfo);
    } catch (e) {
      debugPrint('[RevenueCat] Error logging in user: $e');
    }
  }

  /// Reset RevenueCat to anonymous user on sign-out
  Future<void> logoutUser() async {
    if (_useMockMode) {
      debugPrint('[RevenueCat] logoutUser skipped (mock mode)');
      return;
    }
    if (_apiKeyAndroid.isEmpty && _apiKeyIOS.isEmpty) {
      debugPrint('[RevenueCat] logoutUser skipped (no API key)');
      return;
    }

    try {
      debugPrint('[RevenueCat] Logging out user...');
      await Purchases.logOut();
      _currentTier = SubscriptionTier.starter;
      debugPrint('[RevenueCat] Logout complete, tier reset to Starter');
    } catch (e) {
      debugPrint('[RevenueCat] Error logging out user: $e');
      _currentTier = SubscriptionTier.starter;
    }

    // Reset usage tracking to prevent cross-user quota leaks
    _aiSuggestionsUsedToday = 0;
    _lastSuggestionDate = null;
    _aiReportsUsedThisMonth = 0;
    _lastReportDate = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAISuggestionsUsed);
      await prefs.remove(_keyLastSuggestionDate);
      await prefs.remove(_keyAIReportsUsed);
      await prefs.remove(_keyLastReportDate);
    } catch (e) {
      debugPrint('[RevenueCat] Error clearing usage storage: $e');
    }
  }

  // --- Storage helpers for rate limiting ---

  Future<void> _loadUsageFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _aiSuggestionsUsedToday = prefs.getInt(_keyAISuggestionsUsed) ?? 0;

      final dateStr = prefs.getString(_keyLastSuggestionDate);
      if (dateStr != null) {
        _lastSuggestionDate = DateTime.tryParse(dateStr);
      }

      // Reset if it's a new day
      if (_lastSuggestionDate != null) {
        final now = DateTime.now();
        final isSameDay =
            _lastSuggestionDate!.year == now.year &&
            _lastSuggestionDate!.month == now.month &&
            _lastSuggestionDate!.day == now.day;
        if (!isSameDay) {
          _aiSuggestionsUsedToday = 0;
          _lastSuggestionDate = null;
        }
      }

      // Load AI report usage
      _aiReportsUsedThisMonth = prefs.getInt(_keyAIReportsUsed) ?? 0;

      final reportDateStr = prefs.getString(_keyLastReportDate);
      if (reportDateStr != null) {
        _lastReportDate = DateTime.tryParse(reportDateStr);
      }

      // Reset if it's a new month
      if (_lastReportDate != null) {
        final now = DateTime.now();
        final isSameMonth =
            _lastReportDate!.year == now.year &&
            _lastReportDate!.month == now.month;
        if (!isSameMonth) {
          _aiReportsUsedThisMonth = 0;
          _lastReportDate = null;
        }
      }

      await _saveUsageToStorage();
    } catch (e) {
      debugPrint('Error loading subscription usage: $e');
    }
  }

  Future<void> _saveUsageToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyAISuggestionsUsed, _aiSuggestionsUsedToday);
      if (_lastSuggestionDate != null) {
        await prefs.setString(
          _keyLastSuggestionDate,
          _lastSuggestionDate!.toIso8601String(),
        );
      }
      await prefs.setInt(_keyAIReportsUsed, _aiReportsUsedThisMonth);
      if (_lastReportDate != null) {
        await prefs.setString(
          _keyLastReportDate,
          _lastReportDate!.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error saving subscription usage: $e');
    }
  }

  /// For testing: Set the subscription tier manually
  void setTierForTesting(SubscriptionTier tier) {
    if (_useMockMode) {
      _currentTier = tier;
      debugPrint('Test tier set to: ${tier.displayName}');
    }
  }
}
