import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { compile } from '../src/compiler.ts';
import { findFiles, processWat, runWasm } from './utils.ts';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const testDataDir = path.join(projectRoot, 'testdata');

async function run() {
  const jsFiles = findFiles(testDataDir, '.js', ['run.js', 'run.ts']);

  console.log(`Found ${jsFiles.length} JS examples in ${testDataDir}:`, jsFiles);

  for (const file of jsFiles) {
    console.log(`\n--- Processing ${file} ---`);
    const filePath = path.join(testDataDir, file);
    const jsSource = fs.readFileSync(filePath, 'utf-8');

    console.log('Compiling to WAT...');
    let watText = '';
    try {
      watText = compile(jsSource);
    } catch (e) {
      console.error(`Compilation failed for ${file}:`, e);
      process.exit(1);
    }

    const watPath = path.join(testDataDir, `${file.replace('.js', '.wat')}`);
    fs.writeFileSync(watPath, watText);
    console.log(`WAT written to ${watPath}`);

    console.log('Parsing WAT with Binaryen...');
    let binary: Uint8Array;
    try {
      const result = processWat(watText);
      binary = result.binary;
    } catch (e) {
      console.error(`Binaryen processing failed for ${file}:`, e);
      process.exit(1);
    }

    const wasmPath = path.join(testDataDir, `${file.replace(/\.js$/, '.wasm')}`);
    fs.writeFileSync(wasmPath, binary);
    console.log(`WASM written to ${wasmPath}`);

    try {
      let output = '';
      const imports = {
        env: {
          print_i32: (val: number) => {
            output += val + '\n';
          },
          print_f64: (val: number) => {
            output += val + '\n';
          },
          print_char: (val: number) => {
            output += String.fromCharCode(val);
          },
        },
      };

      const instance = await runWasm(binary, imports);
      const main = instance.exports.main as () => void;

      if (typeof main === 'function') {
        main();
      } else {
        console.error(`Example ${file} does not export a 'main' function.`);
        continue;
      }

      console.log(`Execution output:\n${output}`);

      const outPath = path.join(testDataDir, `${file.replace(/\.js$/, '.out')}`);
      fs.writeFileSync(outPath, output);
      console.log(`Output written to ${outPath}`);
    } catch (e) {
      console.error(`Execution failed for ${file}:`, e);
      process.exit(1);
    }
  }
  console.log('\nAll examples processed successfully!');
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
