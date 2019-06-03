//
// boot into 'beacon' mode, where we poll for update files from mission control
//

if addons:rt:hasconnection(ship) and not volume(1):exists("bootstrap") {
  copypath("0:/lib/bootstrap", "").
}

runpath("1:/bootstrap").

function try_execute_update {
  parameter name.

  if has_file(name, 0) {
    file_receive(name).
    movepath("1:/" + name, "update.ks").
    run update.ks. deletepath("1:/update.ks").
  }
}

until false {
  // if there are new instructions for this ship at KSC then download those and execute
  if addons:rt:hasconnection(ship) {
    notify("Checking for updates [uuid=" + core:tag + "]...").

    try_execute_update("uuid-" + core:tag + "-update.ks").
    try_execute_update("name-" + ship:name + "-update.ks").

    // reboot if the update script requested it
    if (defined _BOOTLOADER_SHOULD_REBOOT) {
      reboot.
    }
  }

  // wait for a startup file to get things rolling
  if has_file("startup.ks", 1) {
    run startup.ks.

    // we are now done with the boot & startup sequence, return control to user
    break.
  }

  // if we don't have a connection, wait for one because we can't recieve
  // updates until we do, otherwise just pause a bit so we don't hammer the CPU
  if not addons:rt:hasconnection(ship) {
    wait until addons:rt:hasconnection(ship).
  } else {
    wait 0.5.
  }
}
