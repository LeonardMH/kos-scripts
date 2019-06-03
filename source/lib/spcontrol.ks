// unfurl all available solar panels, returns the number of solar panels that
// were unfurled and also safely handles the case where you are playing in
// career mode and have not yet unlocked custom action groups
function solar_panel_extend {
  set mt to "ModuleDeployableSolarPanel".

  if not career():candoactions {
    return 0.
  }

  set sp_count to 0.

  for sp in ship:partsnamedpattern("solarPanels") {
    if sp:hasmodule(mt) {
      sp:getmodule(mt):doaction("extend solar panel", true).
      set sp_count to sp_count + 1.
    }
  }

  return sp_count.
}
