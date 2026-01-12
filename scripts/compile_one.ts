import { compile } from '../src/compiler.ts';
import * as fs from 'fs';
import * as path from 'path';

const filePath = process.argv[2];
const content = fs.readFileSync(filePath, 'utf-8');
const wat = compile(content);
console.log(wat);
