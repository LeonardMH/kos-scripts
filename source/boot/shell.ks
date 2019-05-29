//
// boot into 'shell' mode, where we do nothing other than bootstrapping and
// opening the terminal
//

if not (defined _LOADED_BOOTSTRAP) and addons:rt:hasconnection(ship) {
  copypath("0:/leolib/lib_bootstrap", "").
  compile lib_bootstrap. deletepath("1:/lib_bootstrap.ks").
  runoncepath("1:/lib_bootstrap").
}

// automatically open the terminal window
clearscreen.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").