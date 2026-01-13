function main() {
  let a = 10;
  let b = 20;
  let c = a + b; // i32 + i32 -> i32 (30)
  console.log(c);

  let d = 2.5;
  let e = a + d; // i32 + f64 -> f64 (12.5)
  console.log(e);

  let f = 5.5;
  let g = f + a; // f64 + i32 -> f64 (15.5)
  console.log(g);

  let h = 1.1;
  let i = d + h; // f64 + f64 -> f64 (3.6)
  console.log(i);

  // Loop to exercise cache (conceptually)
  let sum = 0;
  // Use a loop to trigger the same call site multiple times
  // 0 + 1 + 2 + 3 + 4 = 10
  for (let j = 0; j < 5; j++) {
    sum = sum + j;
  }
  console.log(sum);
}
