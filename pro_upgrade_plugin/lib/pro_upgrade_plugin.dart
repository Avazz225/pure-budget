import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ProUpgradePlugin {
  static const MethodChannel _channel = MethodChannel('pro_upgrade_plugin');

  /// Prüft, ob der Pro-Status aktiv ist.
  /// Falls nicht gekauft, kann optional ein Kauf-Link geöffnet werden.
  static Future<bool> checkProUpgrade({
    required String purchaseUrl,
    required String productId,
  }) async {
    try {
      final bool purchased = await _channel.invokeMethod(
        'checkProUpgrade',
        {
          'purchaseUrl': purchaseUrl,
          'productId': productId,
        },
      );
      return purchased;
    } catch (e) {
      if (kDebugMode) {
        print('ProUpgradePlugin Error: $e');
      }
      return false;
    }
  }
}
