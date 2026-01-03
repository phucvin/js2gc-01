// This script compiles a single JS file to WAT and prints it to stdout
import { compile } from '../src/compiler/index.ts';
import fs from 'fs';
import path from 'path';

const args = process.argv.slice(2);
if (args.length < 1) {
    console.error('Usage: node scripts/compile_one.ts <file.js> [options]');
    process.exit(1);
}

const filepath = args[0];
const source = fs.readFileSync(filepath, 'utf8');

const options = {
    enableInlineCache: true,
    disableStrings: args.includes('--disable-strings')
};

try {
    const wat = compile(source, options);
    console.log(wat);
} catch (e) {
    console.error(e);
    process.exit(1);
}
