function other() {
  return 42;
}

function main_calc() {
  return other();
}

export function main() { console.log(main_calc()); }
