function main() {
  let obj = { x: 10 };
  obj.inc = function(v) {
    return this.x + v;
  };
  console.log(obj.inc(5));

  let obj2 = { y: 20 };
  // Arrow function should NOT capture dynamic this, but this from scope.
  // In main, this is undefined/global (which we might handle as null).
  obj2.bad = () => {
    return this; // Should be null/undefined, definitely not obj2
  };
  console.log(obj2.bad());
}
