// ----------------------------------------------------------------------------
// functions
// ----------------------------------------------------------------------------
function gravitational_acceleration {
  // vessel to calculate this for (defaults to active ship)
  parameter ves is ship.

  // orbital body to calculate in relation to (defaults to body the selected
  // vessel is currently orbiting)
  parameter orb is ves:body.

  set radius to orb:radius + orb:altitudeof(ves:position).
  return orb:mu / (radius ^ 2).
}

function get_throttle_for_twr {
  parameter targetTWR.
  parameter ves is ship.

  set g to gravitational_acceleration().

  // if we haven't yet staged through to a thrust producing stage, keep the
  // throttle pinned
  if ves:availablethrust = 0 {
    return 1.0.
  }

  return targetTWR * ves:mass * g / ves:availablethrust.
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
  } else if v >= 1000 and v < 1400 {
    return heading(90, 30).
  } else if v >= 1400 or h < 32000 {
    return heading(90, 25).
  } else if h > 32000 {
    return heading(90, 10).
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
