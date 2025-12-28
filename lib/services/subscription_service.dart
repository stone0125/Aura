import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class SubscriptionService {
  static const _apiKeyAndroid = 'test_xfOnOBMnkKIucZoksIYStOMZNWR';
  static const _apiKeyIOS = 'appl_placeholder_api_key';

  bool _isPro = false;
  bool get isPro => _isPro;

  Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKeyAndroid);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKeyIOS);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
      await _checkSubscriptionStatus();
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _isPro = customerInfo.entitlements.all['pro']?.isActive ?? false;

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _isPro = customerInfo.entitlements.all['pro']?.isActive ?? false;
      });
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
    }
  }

  /// Presentations the RevenueCat Paywall.
  /// If [offering] is provided, it shows that specific offering.
  /// Otherwise it shows the current default offering.
  Future<void> presentPaywall({Offering? offering}) async {
    try {
      final paywallResult = await RevenueCatUI.presentPaywall(
        offering: offering,
        displayCloseButton: true,
      );

      // After paywall closes, re-check status just in case
      await _checkSubscriptionStatus();
      debugPrint('Paywall result: $paywallResult');
    } catch (e) {
      debugPrint('Error presenting paywall: $e');
    }
  }

  /// Presents the Customer Center (Self-Service management).
  Future<void> presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('Error presenting customer center: $e');
    }
  }

  Future<List<Package>> getOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
    } catch (e) {
      debugPrint('Error fetching offerings: $e');
    }
    return [];
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      PurchaseResult purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      CustomerInfo customerInfo = purchaseResult.customerInfo;
      _isPro = customerInfo.entitlements.all['pro']?.isActive ?? false;
      return _isPro;
    } catch (e) {
      debugPrint('Error purchasing package: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _isPro = customerInfo.entitlements.all['pro']?.isActive ?? false;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }
}
