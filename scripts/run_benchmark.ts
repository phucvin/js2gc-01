import binaryen from 'binaryen';
import * as fs from 'fs';
import * as path from 'path';
import * as vm from 'vm';
import { fileURLToPath } from 'url';
import { compile } from '../src/compiler.ts';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const benchmarkDir = path.join(projectRoot, 'benchmark');

async function run() {
    if (!fs.existsSync(benchmarkDir)) {
        console.error(`Benchmark directory not found: ${benchmarkDir}`);
        process.exit(1);
    }
    const files = fs.readdirSync(benchmarkDir);
    const jsFiles = files.filter(f => f.endsWith('.js'));

    console.log(`Found ${jsFiles.length} JS benchmarks in ${benchmarkDir}:`, jsFiles);

    for (const file of jsFiles) {
        console.log(`\n--- Benchmarking ${file} ---`);
        const filePath = path.join(benchmarkDir, file);
        const jsSource = fs.readFileSync(filePath, 'utf-8');

        // Compile to WASM
        console.log("Compiling to WAT...");
        let watText = "";
        try {
            watText = compile(jsSource);
        } catch (e) {
             console.error(`Compilation failed for ${file}:`, e);
             continue;
        }

        const watPath = path.join(benchmarkDir, `${file.replace('.js', '.wat')}`);
        fs.writeFileSync(watPath, watText);

        const module = binaryen.parseText(watText);
        module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.Strings);

        // Optimize? The compiler currently doesn't optimize much, but let's stick to what run_testdata does
        // which is basically just parse and emit.
        // Wait, run_testdata doesn't call optimize.

        if (!module.validate()) {
            console.error(`Validation failed for ${file}`);
            continue;
        }

        const binary = module.emitBinary();
        module.dispose();

        // Prepare Wasm Execution
        let wasmDuration = 0;
        try {
            const compiled = await WebAssembly.compile(binary as any);
            let output = "";
            const imports = {
                env: {
                    print_i32: (val: number) => { output += val + "\n"; },
                    print_f64: (val: number) => { output += val + "\n"; },
                    print_string: (val: string) => { output += val + "\n"; },
                }
            };
            const instance = await WebAssembly.instantiate(compiled, imports);
            const main = (instance.exports.main || instance.exports.test) as () => void;

            if (typeof main !== 'function') {
                console.error(`No main/test export in ${file}`);
                continue;
            }

            const start = performance.now();
            main();
            const end = performance.now();
            wasmDuration = end - start;
            console.log(`Wasm Output: ${output.trim()}`);
            console.log(`Wasm Duration: ${wasmDuration.toFixed(4)} ms`);

            // Save output
            const outPath = path.join(benchmarkDir, `${file.replace('.js', '.out')}`);
            fs.writeFileSync(outPath, output);

        } catch (e) {
            console.error(`Wasm execution failed:`, e);
            continue;
        }

        // Prepare JS Execution
        let jsDuration = 0;
        try {
            let output = "";
            const context = vm.createContext({
                console: {
                    log: (...args: any[]) => {
                        output += args.join(' ') + "\n";
                    }
                }
            });
            const script = new vm.Script(jsSource);
            script.runInContext(context);

            const main = context.main; // Assuming global function declaration creates a property on global object
            // Note: in strict mode or modules, top level vars might not be on global object.
            // But our compiler treats them as script globals.

            if (typeof main === 'function') {
                const start = performance.now();
                main();
                const end = performance.now();
                jsDuration = end - start;
                console.log(`JS Output: ${output.trim()}`);
                console.log(`JS Duration: ${jsDuration.toFixed(4)} ms`);
            } else {
                 console.log("Could not find main function in JS context. Running top-level code was the execution?");
                 // If the code ran top-level during runInContext, that's not comparable if we included that in compilation time.
                 // But our pattern is defining functions and calling main.
                 // If main is not defined, maybe it was a script that just ran?
                 // But for Wasm we call export 'main'.
            }

        } catch (e) {
            console.error(`JS execution failed:`, e);
        }

        if (wasmDuration > 0 && jsDuration > 0) {
            const ratio = wasmDuration / jsDuration;
            console.log(`Ratio (Wasm/JS): ${ratio.toFixed(2)}x (Lower is better)`);
            if (ratio < 1) {
                console.log(`Result: Wasm is ${(1/ratio).toFixed(2)}x faster`);
            } else {
                console.log(`Result: JS is ${ratio.toFixed(2)}x faster`);
            }
        }
    }
}

run().catch(e => {
    console.error(e);
    process.exit(1);
});
