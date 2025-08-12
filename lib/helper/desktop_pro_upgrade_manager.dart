import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';
import 'package:pro_upgrade_plugin/pro_upgrade_plugin.dart';

class ProUpgradeManager {
  static const _productId = proVersionProductIdDesktop;
  static const _purchaseUrl = proVersionWindowsPurchaseUrl;

  Future<void> ensureProUpgrade({
    required bool isProLocally,
    required Future<void> Function() setProStatusLocally,
  }) async {
    try {
      if (Platform.isMacOS) {
        await _buyOnMac();
      } else if (Platform.isWindows) {
        await _buyOnWindows();
      }
      await setProStatusLocally();
    } catch (e) {
      Logger().error("$e", tag: "desktopUpgrade");
    }
  }

  Future<void> _buyOnMac() async {
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
  }

  Future<void> _buyOnWindows() async {
    bool isPro = await ProUpgradePlugin.checkProUpgrade(
      purchaseUrl: _purchaseUrl, 
      productId: _productId,
    );

    debugPrint(isPro.toString());
  }
}
