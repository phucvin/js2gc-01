function a() { return 1; }
function b() { return 2; }
function main() { return a() + b(); }

export function test() { console.log(main()); }
