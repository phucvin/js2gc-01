function main() {
    let p = { a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, val: 0  };
    let o = {};
    set_prototype(o, p);
    for (let i = 0; i < 1000000; i++) {
        o.val = o.val + 1;
    }
    console.log(o.val);
}
