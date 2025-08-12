import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pro_upgrade_plugin_method_channel.dart';

abstract class ProUpgradePluginPlatform extends PlatformInterface {
  /// Constructs a ProUpgradePluginPlatform.
  ProUpgradePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static ProUpgradePluginPlatform _instance = MethodChannelProUpgradePlugin();

  /// The default instance of [ProUpgradePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelProUpgradePlugin].
  static ProUpgradePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ProUpgradePluginPlatform] when
  /// they register themselves.
  static set instance(ProUpgradePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
