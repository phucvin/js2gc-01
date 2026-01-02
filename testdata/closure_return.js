function main() {
  let makeAdder = (x) => {
    return (y) => x + y;
  };
  let add5 = makeAdder(5);
  console.log(add5(10));
}
