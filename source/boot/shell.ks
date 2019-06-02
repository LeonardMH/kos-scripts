//
// boot into 'shell' mode, where we do nothing other than bootstrapping and
// opening the terminal
//

if addons:rt:hasconnection(ship) and not volume(1):exists("bootstrap") {
  copypath("0:/lib/bootstrap", "").
}

runpath("1:/bootstrap").

// automatically open the terminal window
clearscreen.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
