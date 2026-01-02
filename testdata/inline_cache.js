function main() {
  const obj = { x: 1, y: 2 };
  let sum = 0;
  for (let i = 0; i < 1000; i++) {
    sum = sum + obj.y;
  }
  console.log(sum);
}
