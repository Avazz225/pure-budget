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
        result = await _buyOnMac();
      } else if (Platform.isWindows) {
        result = await _buyOnWindows();
      }
      await budgetState.updateIsDesktopPro(result);
    } catch (e) {
      _logger.error("$e", tag: "desktopUpgrade");
    }
  }

  Future<bool> _buyOnMac() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) throw Exception("App Store not available");

    final products = await InAppPurchase.instance
        .queryProductDetails({_productId});
    if (products.productDetails.isEmpty) {
      throw Exception("Product not found");
    }

    final purchaseParam =
        PurchaseParam(productDetails: products.productDetails.first);

    await InAppPurchase.instance
      .buyNonConsumable(purchaseParam: purchaseParam);
    return true;
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
