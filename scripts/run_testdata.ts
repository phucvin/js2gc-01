import binaryen from 'binaryen';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { findFiles, compileToWat, createWasmModule, runWasm, getPrintImports } from './utils.ts';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const testDataDir = path.join(projectRoot, 'testdata');

async function run() {
    // Exclude run.ts and run.js if they exist (though findFiles filters by ext, we need to filter names)
    const files = findFiles(testDataDir, '.js').filter(f => f !== 'run.js');

    console.log(`Found ${files.length} JS examples in ${testDataDir}:`, files);

    for (const file of files) {
        console.log(`\n--- Processing ${file} ---`);
        const filePath = path.join(testDataDir, file);
        const jsSource = fs.readFileSync(filePath, 'utf-8');

        console.log("Compiling to WAT...");
        let watText = "";
        try {
            watText = compileToWat(jsSource);
        } catch (e) {
             console.error(`Compilation failed for ${file}:`, e);
             process.exit(1);
        }

        const watPath = path.join(testDataDir, `${file.replace('.js', '.wat')}`);
        fs.writeFileSync(watPath, watText);
        console.log(`WAT written to ${watPath}`);

        console.log("Parsing WAT with Binaryen...");
        let module: binaryen.Module;
        let binary: Uint8Array;

        try {
            const result = await createWasmModule(watText);
            module = result.module;
            binary = result.binary;
        } catch (e) {
             console.error(`Binaryen processing failed for ${file}:`, e);
             process.exit(1);
        }

        const wasmPath = path.join(testDataDir, `${file.replace(/\.js$/, '.wasm')}`);
        fs.writeFileSync(wasmPath, binary);
        console.log(`WASM written to ${wasmPath}`);

        module.dispose();

        try {
            let output = "";
            const imports = getPrintImports((str) => output += str);

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
    console.log("\nAll examples processed successfully!");
}

run().catch(e => {
    console.error(e);
    process.exit(1);
});
