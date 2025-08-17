import 'dart:async';
import 'dart:io' show Platform;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:windows_store/windows_store.dart';

class ProUpgradeManager {
  static final _productId = (Platform.isWindows) ? proVersionProductIdWindows : proVersionProductIdMac;
  final Logger _logger = Logger();

  Future<void> ensureProUpgrade({
    required bool isProLocally,
    required BudgetState budgetState,
  }) async {
    try {
      bool result = false;
      if (Platform.isMacOS) {
        await _restorePurchase(budgetState);
        if (budgetState.isDesktopPro) {
          return;
        }
        await _buyOnMac(budgetState);
      } else if (Platform.isWindows) {
        result = await _buyOnWindows();
        await budgetState.updateIsDesktopPro(result);
      }
    } catch (e) {
      _logger.error("$e", tag: "desktopUpgrade");
    }
  }

  Future<void> _restorePurchase(BudgetState budgetState) async {
    final completer = Completer<void>();

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) throw Exception("App Store not available");

    final subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchases) async {
        _logger.debug("Processing purchases", tag: "desktopUpgrade");
        for (final purchase in purchases) {
          if (purchase.productID == _productId) {
            if (purchase.status == PurchaseStatus.purchased ||
                purchase.status == PurchaseStatus.restored) {
              _logger.debug("Purchase or restore found", tag: "desktopUpgrade");
              await budgetState.updateIsDesktopPro(true);
              if (!completer.isCompleted) completer.complete();
              return;
            }
          }
        }
      },
      onError: (error) {
        _logger.error("Error in purchase stream: $error", tag: "desktopUpgrade");
        if (!completer.isCompleted) completer.completeError(error);
      },
    );

    try {
      _logger.debug("Restoring purchases", tag: "desktopUpgrade");
      await InAppPurchase.instance.restorePurchases();
      await completer.future;
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> _buyOnMac(BudgetState budgetState) async {
    final completer = Completer<void>();

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) throw Exception("App Store not available");

    final subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchases) async {
        _logger.debug("Processing purchases", tag: "desktopUpgrade");
        for (final purchase in purchases) {
          if (purchase.productID == _productId) {
            if (purchase.status == PurchaseStatus.purchased ||
                purchase.status == PurchaseStatus.restored) {
              _logger.debug("Purchase or restore found", tag: "desktopUpgrade");
              await budgetState.updateIsDesktopPro(true);
              if (!completer.isCompleted) completer.complete();
              return;
            }
          }
        }
      },
      onError: (error) {
        _logger.error("Error in purchase stream: $error", tag: "desktopUpgrade");
        if (!completer.isCompleted) completer.completeError(error);
      },
    );

    try {
      _logger.debug("Executing purchases", tag: "desktopUpgrade");
      final products =
          await InAppPurchase.instance.queryProductDetails({_productId});
      if (products.productDetails.isEmpty) {
        throw Exception("Product not found");
      }

      final purchaseParam =
          PurchaseParam(productDetails: products.productDetails.first);
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      await completer.future;
    } finally {
      await subscription.cancel();
    }
  }

  Future<bool> _buyOnWindows() async {
    final windowsStorePlugin = WindowsStoreApi();
    final license = await windowsStorePlugin.getAppLicenseAsync();

    _logger.debug(license.isActive.toString(), tag: "desktopUpgrade");
    _logger.debug(license.isTrial.toString(), tag: "desktopUpgrade");
    _logger.debug(license.skuStoreId.toString(), tag: "desktopUpgrade");
    _logger.debug(license.trialUniqueId.toString(), tag: "desktopUpgrade");
    _logger.debug(license.trialTimeRemaining.toString(), tag: "desktopUpgrade");
    
    if (license.isTrial){
      const url = proVersionWindowsPurchaseUrl;
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
    return !license.isTrial;
  }
}
