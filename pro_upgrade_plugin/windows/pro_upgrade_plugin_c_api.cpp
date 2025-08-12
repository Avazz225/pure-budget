#include "include/pro_upgrade_plugin/pro_upgrade_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "pro_upgrade_plugin.h"

void ProUpgradePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  pro_upgrade_plugin::ProUpgradePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
