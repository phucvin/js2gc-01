function main() {
  let p = { a: 10 };
  let o = { __proto__: p, b: 20 };

  console.log(o.b);
  console.log(o.a);

  let o2 = { __proto__: p, b: 30 };
  console.log(o2.a);

  let o3 = { __proto__: o, c: 40 };
  console.log(o3.a);
  console.log(o3.b);
  console.log(o3.c);

  console.log(o3.d);

  // Prototype chain modification (if we supported assignment, but here just testing structure)
  // Since we only support object literals for now, this is enough.
}
