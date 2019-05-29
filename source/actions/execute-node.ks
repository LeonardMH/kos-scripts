// check that there is a planned manuever node, if not exit as we can't do anything
if not hasnode {
  print "Exiting".
}

set nd to nextnode.

print "Node in: " + round(nd:eta) + ", dV: " + round(nd:deltav:mag).

set max_acc to ship:maxthrust / ship:mass.
set burn_duration to nd:deltav:mag / max_acc.
print "Rough burn estimate: " + round(burn_duration) + "s".

// wait until we are at the halfway burn point
kuniverse:timewarp:warpto(time:seconds + nd:eta - (burn_duration / 2) - 30).
wait until nd:eta <= ((burn_duration / 2) + 25).

set np to nd:deltav.
lock steering to np.

// wait until burn vector and ship steering are aligned
wait until vang(np, ship:facing:vector) < 0.25.

// the ship is facing in the right direction, wait for burn time
wait until nd:eta <= (burn_duration / 2).

// we only need to lock throttle once to a certain variable in the beginning of
// the loop, and adjust only the variable itself inside it
set tset to 0.
lock throttle to tset.

// initial deltav
set dv0 to nd:deltav.

until false
{
  // recalculate current max_acceleration, as it changes while we burn through fuel
  set max_acc to ship:maxthrust / ship:mass.

  // throttle is 100% until there is less than 1 second of time left to burn
  // when there is less than 1 second - decrease the throttle linearly
  set tset to min(nd:deltav:mag / max_acc, 1).

  // here's the tricky part, we need to cut the throttle as soon as our
  // nd:deltav and initial deltav start facing opposite directions
  //
  // this check is done via checking the dot product of those 2 vectors
  if vdot(dv0, nd:deltav) < 0
  {
    print "End Burn:".
    print "dV " + round(nd:deltav:mag, 1) + "m/s".
    print "vdot: " + round(vdot(dv0, nd:deltav), 1).

    lock throttle to 0.

    break.
  }

  // we have very little left to burn, less than 0.1m/s
  if nd:deltav:mag < 0.1
  {
    print "Finalizing Burn:".
    print "dV " + round(nd:deltav:mag, 1) + "m/s".
    print "vdot: " + round(vdot(dv0, nd:deltav), 1).

    // burn slowly until our node vector starts to drift significantly from
    // initial vector this usually means we are on point
    wait until vdot(dv0, nd:deltav) < 0.5.

    lock throttle to 0.

    print "End Burn:".
    print "dV " + round(nd:deltav:mag, 1) + "m/s".
    print "vdot: " + round(vdot(dv0, nd:deltav), 1).

    break.
  }
}

// we no longer need the maneuver node
remove nd.

notify("Node executed, returning control...").
lock throttle to 0. set ship:control:pilotmainthrottle to 0.

if not (defined _EXECUTING_GUI_BOOTLOADER) {
  reboot.
}
