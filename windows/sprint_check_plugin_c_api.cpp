#include "include/sprint_check/sprint_check_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "sprint_check_plugin.h"

void SprintCheckPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  sprint_check::SprintCheckPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
