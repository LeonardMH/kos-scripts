//-----------------------------------------------------------------------------
// load dependencies
//-----------------------------------------------------------------------------

// if we have a connection to KSC and have not already copied over our
// dependencies, do so now
for lib in list("lib_fileop", "lib_ui") {
  if not (defined notify) and addons:rt:hasconnection(ship) {
    // download the requested library
    copypath("0:/leolib/" + lib, "").
    // compile the library and delete source file to conserve space
    compile lib. deletepath("1:/" + lib + ".ks").
  }

  runoncepath(lib).
}

//-----------------------------------------------------------------------------
// bootup procedures
//-----------------------------------------------------------------------------

// create/get id info for this ship
if has_file("identity.json", 1) {
  set sid to readjson("1:/identity.json").
} else {
  set intMax to 2147483647. // 0x7FFFFFFF (32-bit signed)

  set sid to lexicon(
    "uuid", mod(round(random(), 10) * (10 ^ 10), intMax),
    "guid", 0,
    "name", ship:name
  ).

  writejson(sid, "1:/identity.json").
  writejson(sid, "0:/" + sid["guid"] + "-" + sid["uuid"] + "-identity.json").
}

function try_execute_update {
  parameter name.
  parameter shouldDelete.

  if has_file(name, 0) {
    if shouldDelete {
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

    try_execute_update("uuid:" + sid["uuid"] + "-update.ks", true).
    try_execute_update("name:" + sid["name"] + "-update.ks", true).
    try_execute_update("guid:" + sid["guid"] + "-update.ks", false).

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
