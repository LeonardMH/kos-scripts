function is_clamped_to_ground {
  parameter clampName is "launchClamp".
  parameter vessel is ship.

  set clampList to vessel:partsnamedpattern(clampName).

  return clampList:length > 0.
}

function notify_countdown {
  parameter startFrom is 3.

  from {local countdown is startFrom.} until countdown = 0 step {set countdown to countdown - 1.} do {
    notify("T-" + countdown).
    wait 1.
  }
}

// set inital throttle and directional controls
set mySteer to heading(90, 90).
set myThrottle to 1.0.

lock steering to mySteer.
lock throttle to myThrottle.

// countdown loop running from 3 to 0
clearscreen.
notify_countdown(3).

// if initial stage is engine held by support structure, immediately stage it 
// away, the launch engine should be staged first otherwise the clamps will release
// the ship onto the ground possibly breaking the engines.
if is_clamped_to_ground() {
  notify("Staging through launch clamps...").
  stage. wait 0.6. stage.
} 

// normal staging logic
when maxthrust = 0 then {
  notify("Moving to next stage...").
  stage. wait 0.6.
  preserve.
}

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

clearscreen.
until ship:apoapsis > 90000 {
  set potentialSteering to get_steering_for_state(ship).
  if potentialSteering = 0 {
    unlock steering.
  } else {
    set mySteer to potentialSteering.
  }

  // above a certain altitude there is no compelling reason to keep thrust TWR
  // limited, pin it
  if ship:altitude > 26000 {
    set myThrottle to 1.0.
  } else {
    set myThrottle to get_throttle_for_twr(1.9).
  }

  print "PITCH: " + mySteer at (0, 15).
  print "AP: " + round(ship:apoapsis, 0) at (0, 16).
  print "Q: " + ship:q at (0, 17).
}

notify("Target AP reached, returning control...").
lock throttle to 0. set ship:control:pilotmainthrottle to 0.
reboot.