import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pro_upgrade_plugin_platform_interface.dart';

/// An implementation of [ProUpgradePluginPlatform] that uses method channels.
class MethodChannelProUpgradePlugin extends ProUpgradePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pro_upgrade_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
