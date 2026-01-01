import { execSync } from "child_process";
import fs from "fs";
import path from "path";

const examplesDir = "binary_api_examples";
const files = fs.readdirSync(examplesDir).filter(f => f.endsWith(".ts") && f !== "run.ts");

console.log(`Found ${files.length} examples.`);

files.forEach(file => {
  console.log(`Running ${file}...`);
  try {
    const output = execSync(`npx ts-node ${path.join(examplesDir, file)}`, { encoding: "utf-8" });
    console.log(output);
  } catch (e) {
    console.error(`Error running ${file}:`, e);
    process.exit(1);
  }
});

console.log("All examples ran successfully.");
