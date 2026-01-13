function main() {
  // 1. Empty object
  let empty = {};

  // 2. Object with one prop
  let one = { a: 1 };

  // 3. Object with two props
  let two = { a: 1, b: 2 };

  // 4. Closure (empty capture)
  let f = () => {};
  f();

  // 5. Closure (with capture)
  let x = 10;
  let g = () => {
    x;
  };
  g();

  // 6. Method call
  let obj = {
    m: () => {},
  };
  obj.m();
}
