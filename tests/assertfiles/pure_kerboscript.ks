function test_language_features {
  parameter vessel is ship.

  // get shortcut variables to vessel velocity and altitude
  set v to vessel:velocity:surface:mag.
  set h to vessel:altitude.

  // always be moving
  if v < 0.1 {
    stage.
  }

  // if vessel has reached target altitude, reboot and allow bootloader to
  // decide next action
  if h > 80000 {
    reboot.
  }

  set steering to heading(90, get_pitch_for_state()).
  set throttle to get_throttle_for_twr(1.9).
}
