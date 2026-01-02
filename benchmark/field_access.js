function main() {
    let o = { val: 0 };
    for (let i = 0; i < 1000000; i++) {
        o.val = o.val + 1;
    }
    console.log(o.val);
}
