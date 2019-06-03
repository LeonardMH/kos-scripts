function tlm_gravitational_acceleration {
  // vessel to calculate this for (defaults to active ship)
  parameter ves is ship.

  // orbital body to calculate in relation to (defaults to body the selected
  // vessel is currently orbiting)
  parameter orb is ves:body.

  set radius to orb:radius + orb:altitudeof(ves:position).
  return orb:mu / (radius ^ 2).
}

function tlm_twr_max {
  // vessel to calculate this for (defaults to active ship)
  parameter ves is ship.
  return ves:availablethrust / (ves:mass * tlm_gravitational_acceleration()).
}

function tlm_twr_cur {
  // vessel to calculate this for (defaults to active ship)
  parameter ves is ship.
  return throttle * tlm_twr_max().
}
