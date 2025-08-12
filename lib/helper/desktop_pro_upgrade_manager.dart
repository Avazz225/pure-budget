import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:jne_household_app/logger.dart';

class ProUpgradeManager {
  static const _windowsChannel = MethodChannel('pro_upgrade_windows');
  static const _productId = "pro_upgrade";

  Future<void> ensureProUpgrade({
    required bool isProLocally,
    required Future<void> Function() setProStatusLocally,
  }) async {
    if (isProLocally) return;

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
    final result = await _windowsChannel.invokeMethod<bool>(
      'buyProduct',
      {"productId": _productId},
    );
    if (result != true) {
      throw Exception("Purchase failed");
    }
  }
}
