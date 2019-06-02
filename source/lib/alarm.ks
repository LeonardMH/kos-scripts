function alm_ping {
  set v0 to getvoice(0).
  v0:play(slidenote("C2", "C5", 0.1, 0.15)).
  wait 0.30.
}

function alm_ping_num {
  parameter num.

  from { local x is 0. } until x = num step { set x to x + 1. } do {
    alm_ping().
    wait until true.
  }
}
