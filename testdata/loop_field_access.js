function main() {
  let obj = { count: 1 };
  let sum = 0;
  for (let i = 0; i < 10; i++) {
    // Access field inside loop
    sum = sum + obj.count;
  }
  console.log(sum);
}
