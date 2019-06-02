//
// boot into 'beacon' mode, where we poll for update files from mission control
//

if addons:rt:hasconnection(ship) and not volume(1):exists("bootstrap") {
  copypath("0:/lib/bootstrap", "").
}

runpath("1:/bootstrap").

function try_execute_update {
  parameter name.
  parameter doDelete.

  if has_file(name, 0) {
    if doDelete {
      file_receive(name).
    } else {
      file_download(name).
    }

    movepath("1:/" + name, "update.ks").
    run update.ks. deletepath("1:/update.ks").
  }
}

until false {
  // if there are new instructions for this ship at KSC then download those and execute
  if addons:rt:hasconnection(ship) {
    notify("Checking for updates...").

    try_execute_update("uuid-" + sid["uuid"] + "-update.ks", true).
    try_execute_update("name-" + sid["name"] + "-update.ks", true).
    try_execute_update("guid-" + sid["guid"] + "-update.ks", false).

    wait 1.
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
    wait 8.
  }
}
