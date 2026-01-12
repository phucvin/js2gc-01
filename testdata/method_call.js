function main() {
  let obj = {};
  obj.add = (a, b) => {
    return a + b;
  };
  console.log(obj.add(1, 2));

  let obj2 = {
    sub: (a, b) => {
      return a - b;
    }
  };
  console.log(obj2.sub(5, 3));
}
