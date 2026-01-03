import os
import subprocess
import sys

def run_tests():
    testdata_dir = "testdata"
    interpreter = "scratch/js_interpreter/js_interpreter"

    if not os.path.exists(interpreter):
        print(f"Error: Interpreter not found at {interpreter}")
        print("Please build it first: cd scratch/js_interpreter && ./build.sh")
        sys.exit(1)

    files = [f for f in os.listdir(testdata_dir) if f.endswith(".js")]
    files.sort()
    passed = 0
    failed = 0

    print(f"Running {len(files)} tests...")

    for f in files:
        js_path = os.path.join(testdata_dir, f)
        out_path = os.path.join(testdata_dir, f.replace(".js", ".out"))

        if not os.path.exists(out_path):
            print(f"[SKIP] {f} - No .out file")
            continue

        with open(out_path, 'r') as out_file:
            expected_output = out_file.read().strip()

        try:
            # Run interpreter
            cmd = [interpreter, js_path]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)

            actual_output = result.stdout.strip()

            if result.returncode != 0:
                print(f"[FAIL] {f} - Non-zero exit code: {result.returncode}")
                print(f"Stderr: {result.stderr}")
                failed += 1
            elif actual_output != expected_output:
                print(f"[FAIL] {f} - Output mismatch")
                print(f"Expected:\n{expected_output}")
                print(f"Actual:\n{actual_output}")
                if result.stderr:
                    print(f"Stderr:\n{result.stderr}")
                failed += 1
            else:
                print(f"[PASS] {f}")
                passed += 1

        except Exception as e:
            print(f"[ERR ] {f} - Exception: {e}")
            failed += 1

    print(f"\nSummary: {passed} passed, {failed} failed")
    if failed > 0:
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
