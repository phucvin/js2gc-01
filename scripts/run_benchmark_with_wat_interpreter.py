import os
import subprocess
import glob
import sys
import time

# Get the directory where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# Project root is one level up from scripts/
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
# The build script puts the binary in scratch/wat_interpreter
INTERPRETER_BIN = os.path.join(PROJECT_ROOT, "scratch", "wat_interpreter", "wat_interpreter")
BENCHMARK_DIR = os.path.join(PROJECT_ROOT, "benchmark")

def run_benchmark(wat_file):
    # Ensure interpreter exists
    if not os.path.exists(INTERPRETER_BIN):
        print(f"Error: Interpreter binary not found at {INTERPRETER_BIN}")
        print("Please build it first (e.g., cd scratch/wat_interpreter && ./build.sh)")
        return None

    # Run interpreter
    try:
        start_time = time.time()
        # The interpreter might output stuff, we can capture it
        result = subprocess.run(
            [INTERPRETER_BIN, wat_file],
            capture_output=True,
            text=True,
            timeout=60
        )
        end_time = time.time()
        duration_ms = (end_time - start_time) * 1000
    except subprocess.TimeoutExpired:
        print(f"TIMEOUT: {wat_file}")
        return None

    if result.returncode != 0:
        print(f"ERROR: {wat_file} returned {result.returncode}")
        print(result.stderr)
        return None

    # Output isn't checked against expected, just measuring time (and success)
    return duration_ms

def main():
    # Only run .wat files in benchmark directory
    files = glob.glob(os.path.join(BENCHMARK_DIR, "*.wat"))
    files.sort()

    if not files:
        print(f"No .wat files found in {BENCHMARK_DIR}")
        sys.exit(1)

    print(f"Found {len(files)} benchmarks.")
    print("| Benchmark | Duration (ms) |")
    print("|---|---|")

    for f in files:
        filename = os.path.basename(f)
        duration = run_benchmark(f)
        if duration is not None:
            print(f"| {filename} | {duration:.2f} |")
        else:
            print(f"| {filename} | FAILED |")

if __name__ == "__main__":
    main()
