function main_val() {
  return 1073741824; // 2^30, too big for signed 31-bit integer?
  // Signed 31-bit range: [-1073741824, 1073741823].
  // So 1073741824 is just outside, should be BoxedI32.
}

export function main() { console.log(main_val()); }
