function main() {
    let o = { x: 1, y: 2, z: 3 };
    let sum = 0;
    for (let i = 0; i < 1000; i++) {
        sum = sum + o.x + o.y + o.z;
    }
    console.log(sum);
}
