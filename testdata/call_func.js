function other() {
  return 42;
}

function main() {
  return other();
}

export function test() { console.log(main()); }
