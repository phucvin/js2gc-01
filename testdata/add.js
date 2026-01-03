function a() { return 1; }
function b() { return 2; }
function main_calc() { return a() + b(); }

export function main() { console.log(main_calc()); }
