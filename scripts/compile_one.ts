import { compile } from '../src/compiler/index.ts';
import fs from 'fs';

const file = process.argv[2];
const source = fs.readFileSync(file, 'utf8');
try {
    const wat = compile(source);
    console.log(wat);
} catch (e) {
    console.error(e);
}
