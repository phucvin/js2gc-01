function makeAdder(x) {
  return (y) => x + y;
}

function main() {
  let add5 = makeAdder(5);
  console.log(add5(10));
}
