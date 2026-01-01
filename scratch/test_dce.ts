import { compile } from '../src/compiler.ts';

const source = `
function deadFunction() {
  return 42;
}

function main() {
  return 1;
}
`;

try {
  const wat = compile(source);
  console.log(wat);
} catch (e) {
  console.error(e);
}
