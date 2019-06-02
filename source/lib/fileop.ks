// check if a file with name exists on the specified volume
function has_file {
  parameter name.
  parameter vol.

  return volume(vol):exists(name).
}

// get a file from KSC, keeping the copy there
function file_download {
  parameter name.

  if has_file(name, 1) {
    deletepath(name).
  }

  copypath("0:/" + name, "").
}

// get a file from KSC, deleting the copy there
function file_receive {
  parameter name.

  file_download(name).

  if has_file(name, 0) {
    deletepath("0:/" + name).
  }
}

// send a file to KSC, keeping a local copy on the ship
function file_upload {
  parameter name.

  if has_file(name, 0) {
    deletepath("0:/" + name).
  }

  copypath("1:/" + name, "0:/" + name).
}

// send a file to KSC, removing the local copy on the ship
function file_transmit {
  parameter name.

  file_upload(name).

  if has_file(name, 1) {
    deletepath(name).
  }
}
