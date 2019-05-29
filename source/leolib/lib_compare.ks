// check if two values are roughly equivalent
function roughly_equal {
  parameter a.
  parameter b.
  parameter roughness_factor.

  return a - roughness_factor < b and a + roughness_factor > b.
}
