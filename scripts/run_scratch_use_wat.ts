import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { processWat } from './utils.ts';
import binaryen from 'binaryen';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const scratchDir = path.join(projectRoot, 'scratch', 'use_wat');

async function run() {
  const files = fs.readdirSync(scratchDir);
  const watFiles = files.filter((f) => f.endsWith('.wat'));

  console.log(`Found ${watFiles.length} WAT examples in ${scratchDir}:`, watFiles);

  for (const file of watFiles) {
    console.log(`\n--- Processing ${file} ---`);
    const filePath = path.join(scratchDir, file);

    try {
      const watText = fs.readFileSync(filePath, 'utf-8');

      console.log('Parsing and Optimizing...');
      // run_scratch_use_wat enables Strings feature
      const result = processWat(watText, {
        features:
          binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.Strings,
        optimize: true,
      });

      if (result.optimizedWat) {
        const optimizedPath = path.join(scratchDir, `${file}.optimized`);
        fs.writeFileSync(optimizedPath, result.optimizedWat);
        console.log(`Optimized WAT written to ${optimizedPath}`);
      }

      try {
        const compiled = await WebAssembly.compile(result.binary as any);
        const instance = await WebAssembly.instantiate(compiled, {});

        const main = instance.exports.main as () => number;
        if (typeof main !== 'function') {
          console.error(`Example ${file} does not export a 'main' function.`);
          continue;
        }

        const runResult = main();
        console.log(`Execution result: ${runResult}`);

        const outPath = path.join(scratchDir, `${file}.out`);
        fs.writeFileSync(outPath, runResult.toString());
        console.log(`Output written to ${outPath}`);
      } catch (e) {
        console.error(`Execution failed for ${file}:`, e);
      }
    } catch (e) {
      console.error(`Processing failed for ${file}:`, e);
    }
  }
  console.log('\nAll examples processed successfully!');
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
