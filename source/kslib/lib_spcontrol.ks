// unfurl all available solar panels
function solar_panel_extend {
  set mt to "ModuleDeployableSolarPanel".

  for sp in ship:partsnamedpattern("solarPanels") {
    if sp:hasmodule(mt) {
      sp:getmodule(mt):doaction("extend solar panel", true).
    }
  }
}
