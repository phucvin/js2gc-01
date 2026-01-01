import binaryen from 'binaryen';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { compile } from '../src/compiler.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
// We are in dist/testdata/run.js, so we need to go up two levels to get to root, then into testdata
// Actually, the user wants the out files in testdata, but the run.js is running from dist.
// If we run `node dist/testdata/run.js`, __dirname is `dist/testdata`.
// We want to access `testdata` in the root.
const projectRoot = path.resolve(__dirname, '../../');
const testDataDir = path.join(projectRoot, 'testdata');

async function run() {
    const files = fs.readdirSync(testDataDir);
    // Exclude run.ts and run.js
    const jsFiles = files.filter(f => f.endsWith('.js') && f !== 'run.js' && f !== 'run.ts');

    console.log(`Found ${jsFiles.length} JS examples in ${testDataDir}:`, jsFiles);

    for (const file of jsFiles) {
        console.log(`\n--- Processing ${file} ---`);
        const filePath = path.join(testDataDir, file);
        const jsSource = fs.readFileSync(filePath, 'utf-8');

        console.log("Compiling to WAT...");
        let watText = "";
        try {
            watText = compile(jsSource);
        } catch (e) {
             console.error(`Compilation failed for ${file}:`, e);
             process.exit(1);
        }

        const watPath = path.join(testDataDir, `${file.replace('.js', '.wat')}`);
        fs.writeFileSync(watPath, watText);
        console.log(`WAT written to ${watPath}`);

        console.log("Parsing WAT with Binaryen...");
        const module = binaryen.parseText(watText);

        console.log("Setting features (GC | ReferenceTypes | Strings)...");
        module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.Strings);

        if (!module.validate()) {
            console.error(`Validation failed for ${file}`);
            process.exit(1);
        }

        const binary = module.emitBinary();
        module.dispose();

        try {
            const compiled = await WebAssembly.compile(binary as any);
            const instance = await WebAssembly.instantiate(compiled, {});

            const main = instance.exports.main as () => any;
            if (typeof main !== 'function') {
                console.error(`Example ${file} does not export a 'main' function.`);
                continue;
            }

            const result = main();
            console.log(`Execution result: ${result}`);

            const outPath = path.join(testDataDir, `${file.replace('.js', '.out')}`);
            fs.writeFileSync(outPath, String(result));
            console.log(`Output written to ${outPath}`);

        } catch (e) {
            console.error(`Execution failed for ${file}:`, e);
            process.exit(1);
        }
    }
    console.log("\nAll examples processed successfully!");
}

run().catch(e => {
    console.error(e);
    process.exit(1);
});
