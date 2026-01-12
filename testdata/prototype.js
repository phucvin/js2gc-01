function main() {
  let proto = {
    x: 10,
    y: 20
  };

  let obj = {
    __proto__: proto,
    x: 100
  };

  console.log(obj.x); // Should be 100 (own property)
  console.log(obj.y); // Should be 20 (inherited)
  console.log(proto.x); // Should be 10

  let deepProto = {
      z: 30
  };

  let midProto = {
      __proto__: deepProto
  };

  let obj2 = {
      __proto__: midProto
  };

  console.log(obj2.z); // Should be 30

  // Test default prototype (Object.prototype mechanism validation)
  // We can't access Object.prototype directly yet, but objects should have it.
  // We can verify that we can create objects without __proto__ and they work.
  let plain = { a: 1 };
  console.log(plain.a);

  // Test missing property
  console.log(plain.missing); // Should be null (or undefined/null in our system)
}
