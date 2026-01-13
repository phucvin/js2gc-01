function main() {
    // 1. Create a prototype object
    let proto = {
        a: 10,
        b: 20
    };

    // 2. Create a child object using Object.create
    let child = Object.create(proto);
    child.c = 30;

    // 3. (Internal helper test removed, now using standard Object.create)

    // 4. Access fields
    console.log(child.c); // Own property: 30
    console.log(child.a); // Prototype property: 10
    console.log(child.b); // Prototype property: 20

    // 5. Shadowing
    child.a = 100;
    console.log(child.a); // Shadowed property: 100
    console.log(proto.a); // Original property: 10

    // 6. Deep prototype chain using Object.create
    let grandChild = Object.create(child);
    grandChild.d = 40;

    console.log(grandChild.d); // Own: 40
    console.log(grandChild.a); // From child (shadowed): 100
    console.log(grandChild.b); // From proto: 20

    // 7. Verify inline cache for prototype access
    // Accessing multiple times to trigger IC
    for (let i = 0; i < 5; i++) {
        console.log(grandChild.b);
    }
}
