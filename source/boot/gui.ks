//
// boot into 'gui' mode, where we present the pilot with a GUI that
// drives all future actions
//

if addons:rt:hasconnection(ship) and not volume(1):exists("bootstrap") {
  copypath("0:/lib/bootstrap", "").
}

runpath("1:/bootstrap").

// the control gui will not be defined here (because it is a pain to
// develop/debug/refresh boot scripts) but will instead be defined as an
// 'action'
//
// this has the secondary benefit of allowing me to show the GUI on a vessel
// that doesn't boot directly to the GUI
if addons:rt:hasconnection(ship) {
  copypath("0:/actions/show-gui.ks", "").
  runpath("show-gui").
}
