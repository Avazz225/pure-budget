#ifndef FLUTTER_PLUGIN_PRO_UPGRADE_PLUGIN_H_
#define FLUTTER_PLUGIN_PRO_UPGRADE_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>
#include <memory>

namespace pro_upgrade_plugin {

class ProUpgradePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ProUpgradePlugin();
  virtual ~ProUpgradePlugin();
};

}  // namespace pro_upgrade_plugin

#endif  // FLUTTER_PLUGIN_PRO_UPGRADE_PLUGIN_H_
