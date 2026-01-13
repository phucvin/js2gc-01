function main() {
  let p = { a: 10 };
  // Create object with prototype
  let c = Object.create(p);
  c.b = 20;

  console.log(c.a); // 10 (inherited)
  console.log(c.b); // 20 (own)

  // Test IC with another object of same shape (if possible)
  // or just verify access works
  let p2 = { a: 30 };
  let c2 = Object.create(p2);
  console.log(c2.a); // 30

  // Deep chain
  let d = Object.create(c);
  console.log(d.a); // 10
  console.log(d.b); // 20
}
