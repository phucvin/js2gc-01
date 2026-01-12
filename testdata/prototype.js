
function main() {
    // 1. Basic Inheritance
    let proto = { parentProp: 10 };
    let obj = { childProp: 20, __proto__: proto };

    console.log(obj.childProp); // 20
    console.log(obj.parentProp); // 10

    // 2. Chain
    let grandProto = { grandProp: 100 };
    let proto2 = { parentProp2: 50, __proto__: grandProto };
    let obj2 = { childProp2: 5, __proto__: proto2 };

    console.log(obj2.childProp2); // 5
    console.log(obj2.parentProp2); // 50
    console.log(obj2.grandProp); // 100

    // 3. Shadowing
    let proto3 = { value: 333 };
    let obj3 = { value: 777, __proto__: proto3 };

    console.log(obj3.value); // 777

    // 4. Missing Property
    // console.log(obj.missing); // Should print 'null' or 'undefined' (currently we print null/undefined as object?)

    // 5. Prototype assignment via variable
    let p = { x: 1 };
    let o = { __proto__: p };
    console.log(o.x); // 1
}
