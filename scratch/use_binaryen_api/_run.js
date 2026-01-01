import { execSync } from "child_process";
import fs from "fs";
import path from "path";
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const targetDir = __dirname;

const files = fs.readdirSync(targetDir).filter(f => f.endsWith(".ts") && f !== "run.ts" && f !== "_run.js");

console.log(`Found ${files.length} examples in ${targetDir}.`);

files.forEach(file => {
  console.log(`Running ${file}...`);
  try {
    const filePath = path.join(targetDir, file);
    // Use npx ts-node to run the TS examples
    const output = execSync(`npx ts-node ${filePath}`, { encoding: "utf-8" });

    // Define output filename
    const outFileName = file.replace(/\.ts$/, ".out");
    const outFilePath = path.join(targetDir, outFileName);

    fs.writeFileSync(outFilePath, output);
    console.log(`  -> Written to ${outFileName}`);
  } catch (e) {
    console.error(`Error running ${file}:`, e);
    process.exit(1);
  }
});

console.log("All examples ran successfully.");
