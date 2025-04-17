//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <sprint_check/sprint_check_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) sprint_check_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SprintCheckPlugin");
  sprint_check_plugin_register_with_registrar(sprint_check_registrar);
}
