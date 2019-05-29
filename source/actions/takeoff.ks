// ----------------------------------------------------------------------------
// functions
// ----------------------------------------------------------------------------
function get_throttle_for_twr {
  parameter targetTWR.
  parameter vessel is ship.

  // TODO: Calculate proper gravity for planetary body
  set g to 9.81.

  // if we haven't yet staged through to a thrust producing stage, keep the
  // throttle pinned
  if vessel:availablethrust = 0 {
    return 1.0.
  }

  return targetTWR * vessel:mass * g / vessel:availablethrust.
}

function get_steering_for_state {
  parameter vessel is ship.
  
  set v to vessel:velocity:surface:mag.
  set h to vessel:altitude.

  if v < 50 {
    return heading(90, 90).
  } else if v >= 50 and v < 100 {
    return heading(90, 85).
  } else if v >= 300 and v < 600 {
    return heading(90, 75).
  } else if v >= 600 and v < 1000 {
    return heading(90, 45).
  } else if v > 1000 and h > 26000 {
    return heading(90, 30).
  }

  // unlock the steering controls
  return 0.
}

function is_clamped_to_ground {
  parameter clampName is "launchClamp".
  parameter vessel is ship.

  return vessel:partsnamedpattern(clampName):length > 0.
}

function get_payload_fairings {
  parameter vessel is ship.

  return vessel:partsnamedpattern("fairing").
}

// ----------------------------------------------------------------------------
// begin script
// ----------------------------------------------------------------------------
set TARGET_AP to 90000.

// set inital throttle and directional controls
set mySteer to heading(90, 90).
set myThrot to 1.0.

lock steering to mySteer.
lock throttle to myThrot.

// if initial stage is engine held by support structure, immediately stage it 
// away, the launch engine should be staged first otherwise the clamps will release
// the ship onto the ground possibly breaking the engines.
if is_clamped_to_ground() {
  notify("Staging through launch clamps...").
  stage. wait until stage:ready. stage.
}

// normal staging logic
when maxthrust = 0 then {
  notify("Staging...").
  stage. wait until stage:ready.
  preserve.
}

// discard payload shell when leaving the atmosphere (if it exists)
set fars to get_payload_fairings().
if fars:length > 0 {
  when ship:altitude > 70000 then {
    notify("Ejecting payload fairings...").

    lock steering to "kill".

    for far in fars {
      far:getmodule("ModuleProceduralFairing"):doevent("deploy").
    }

    lock steering to mySteer.
  }
}

until ship:apoapsis >= TARGET_AP {
  set potentialSteering to get_steering_for_state(ship).

  if potentialSteering = 0 {
    unlock steering.
  } else {
    set mySteer to potentialSteering.
  }

  // above a certain altitude there is no compelling reason to keep thrust TWR
  // limited, pin it
  if ship:altitude > 26000 {
    set myThrot to 1.0.
  } else {
    set myThrot to get_throttle_for_twr(1.9).
  }
}

notify("Target AP reached, returning control...").
lock throttle to 0. set ship:control:pilotmainthrottle to 0.

if not (defined _EXECUTING_GUI_BOOTLOADER) {
  reboot.
}