import * as fs from 'fs';
import * as path from 'path';
import { spawn } from 'child_process';
import { compile } from '../src/compiler.ts';
import type Binaryen from 'binaryen';

// Helper to hold the loaded binaryen module
let binaryen: typeof Binaryen | null = null;

async function loadBinaryen() {
    if (binaryen) return binaryen;
    try {
        const module = await import('binaryen');
        binaryen = module.default as typeof Binaryen;
        return binaryen;
    } catch (e) {
        console.warn("Could not load binaryen:", e);
        return null;
    }
}

// Assume running from project root
const projectRoot = process.cwd();
const benchmarkDir = path.join(projectRoot, 'benchmark');
const interpreterPath = path.join(projectRoot, 'scratch/wat_interpreter/wat_interpreter');

async function runBenchmark(jsSource: string, file: string, enableIC: boolean): Promise<{ duration: number, output: string }> {
    console.log(`Compiling to WAT (IC: ${enableIC})...`);

    await loadBinaryen();

    if (!binaryen) {
        console.error("Binaryen not found, cannot compile.");
        return { duration: Infinity, output: "" };
    }

    let watText = "";
    try {
        // Force disable strings as the interpreter might not support them fully or we want to avoid complexity
        watText = compile(jsSource, { enableInlineCache: enableIC, enableStringRef: false });
    } catch (e) {
         console.error(`Compilation failed for ${file} (IC: ${enableIC}):`, e);
         return { duration: Infinity, output: "" };
    }

    // We need to run a pass to clean up the WAT or ensure it works with the interpreter
    // The interpreter parses WAT directly.
    // However, the interpreter might have specific limitations.
    // Let's rely on the compiler's output.

    const watPath = path.join(benchmarkDir, `${file.replace(/\.js$/, '')}.${enableIC ? 'ic' : 'no_ic'}.interpreter.wat`);
    fs.writeFileSync(watPath, watText);

    // Run the interpreter
    return new Promise((resolve) => {
        const start = performance.now();
        const child = spawn(interpreterPath, [watPath]);

        let stdout = "";
        let stderr = "";

        child.stdout.on('data', (data) => {
            stdout += data.toString();
        });

        child.stderr.on('data', (data) => {
            stderr += data.toString();
        });

        child.on('close', (code) => {
            const end = performance.now();
            const duration = end - start;

            if (code !== 0) {
                console.error(`Interpreter failed for ${file} (IC: ${enableIC}) with code ${code}`);
                console.error(stderr);
                resolve({ duration: Infinity, output: stdout });
            } else {
                resolve({ duration, output: stdout });
            }
        });

        child.on('error', (err) => {
             console.error(`Failed to start interpreter: ${err}`);
             resolve({ duration: Infinity, output: "" });
        });
    });
}

async function run() {
    if (!fs.existsSync(benchmarkDir)) {
        console.error(`Benchmark directory not found: ${benchmarkDir}`);
        process.exit(1);
    }
    if (!fs.existsSync(interpreterPath)) {
        console.error(`Interpreter executable not found: ${interpreterPath}`);
        console.error("Please build the interpreter first (e.g., using build.sh in scratch/wat_interpreter)");
        process.exit(1);
    }

    const files = fs.readdirSync(benchmarkDir);
    const jsFiles = files.filter(f => f.endsWith('.js'));

    console.log(`Found ${jsFiles.length} JS benchmarks in ${benchmarkDir}:`, jsFiles);

    let report = "# Benchmark Results (WAT Interpreter)\n\n";
    report += "| Benchmark | Interpreter IC (ms) | Interpreter No IC (ms) |\n";
    report += "|---|---|---|\n";

    for (const file of jsFiles) {
        console.log(`\n--- Benchmarking ${file} ---`);
        const filePath = path.join(benchmarkDir, file);
        const jsSource = fs.readFileSync(filePath, 'utf-8');

        // Run Interpreter with IC
        const icResult = await runBenchmark(jsSource, file, true);
        if (icResult.duration !== Infinity) {
             console.log(`Interpreter IC Duration: ${icResult.duration.toFixed(4)} ms`);
             console.log(`Output: ${icResult.output.trim()}`);
        }

        // Run Interpreter without IC
        const noIcResult = await runBenchmark(jsSource, file, false);
        if (noIcResult.duration !== Infinity) {
            console.log(`Interpreter No IC Duration: ${noIcResult.duration.toFixed(4)} ms`);
            console.log(`Output: ${noIcResult.output.trim()}`);
        }

        const icTime = icResult.duration !== Infinity ? icResult.duration.toFixed(4) : "N/A";
        const noIcTime = noIcResult.duration !== Infinity ? noIcResult.duration.toFixed(4) : "N/A";

        report += `| ${file} | ${icTime} | ${noIcTime} |\n`;
    }

    console.log("\n" + report);

    // Append to wat_interpreter README
    const readmePath = path.join(projectRoot, 'scratch/wat_interpreter/README.md');
    let readme = "";
    if (fs.existsSync(readmePath)) {
        readme = fs.readFileSync(readmePath, 'utf-8');
    } else {
        readme = "# WAT Interpreter\n\n";
    }

    const benchHeader = "## Benchmark Results";

    // Remove old benchmark output if it exists
    if (readme.includes(benchHeader)) {
        const startIndex = readme.indexOf(benchHeader);
        let endIndex = readme.indexOf("\n## ", startIndex + benchHeader.length);
        if (endIndex === -1) endIndex = readme.length;

        // Remove the old section entirely
        readme = readme.substring(0, startIndex) + readme.substring(endIndex);
    }

    // Trim trailing newlines
    readme = readme.trimEnd();

    // Append new report
    readme += "\n\n" + benchHeader + "\n\n" + report.replace("# Benchmark Results (WAT Interpreter)\n\n", "");

    fs.writeFileSync(readmePath, readme);
    console.log("Updated scratch/wat_interpreter/README.md");
}

run().catch(e => {
    console.error(e);
    process.exit(1);
});
