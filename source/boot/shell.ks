//
// boot into 'shell' mode, where we do nothing other than bootstrapping and
// opening the terminal
//

if addons:rt:hasconnection(ship) and not volume(1):exists("lib_bootstrap") {
  copypath("0:/leolib/lib_bootstrap", "").
  compile lib_bootstrap. deletepath("1:/lib_bootstrap.ks").
}

runpath("1:/lib_bootstrap").

// automatically open the terminal window
clearscreen.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").