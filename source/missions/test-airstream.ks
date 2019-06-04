// Mission: Test AE-FF1 airstream protective shell in flight over Kerbin
//
// Activate the part through the staging sequence when all test conditions are
// met.
//
// Conditions:
//
// - Alt: 55,000m to 61,000m
// - Spd: 90m/s to 1050m/s
@ksx from ("lib/physics") import (grav_accel).

function get_throttle_for_twr {
  parameter targetTWR.
  parameter ves is ship.

  set g to grav_accel().

  // if we haven't yet staged through to a thrust producing stage, keep the
  // throttle pinned
  if ves:availablethrust = 0 {
    return 1.0.
  }

  return targetTWR * ves:mass * g / ves:availablethrust.
}

function safe_stage {
  stage.
  wait until stage:ready.
}

set mySteer to up.
set myThrot to 1.0.

lock steering to mySteer.
lock throttle to myThrot.

set runState to 1.
set twrLimit to 2.0.

// wait for user interruption
until runState = 0 {
  if runState = 1 {
    // start the launch
    stage.
    set runState to 2.
  } else if runState = 2 {
    // waiting for SRB to expire
    if ship:availablethrust < 0.1 {
      safe_stage().
      safe_stage().

      set runState to 3.
    }
  } else if runState = 3 {
    // waiting for contract condition
    set v to ship:velocity:surface:mag.
    set h to altitude.

    if v >= 1000 and h < 55000 {
      set twrLimit to 1.0.
    }

    if v < 1050 and h > 55000 {
      stage.
      set runState to 4.
    }
  } else if runState = 4 {
    set mySteer to heading(90, 0).
    set runState to 5.
  } else if runState = 5 {
    if ship:availablethrust < 0.1 {
      set runState to 6.
    }
  } else if runState = 6 {
    if not chutessafe {
      chutessafe on.
      set runState to 0.
    }
  }

  // adjust throttle to maintain a reasonable ascent
  if runState = 5 {
    set myThrot to 1.0.
  } else {
    set myThrot to get_throttle_for_twr(twrLimit).
  }

  // wait a physics tick
  wait until true.
}.
