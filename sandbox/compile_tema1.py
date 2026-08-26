import subprocess
import glob
import os

files = sorted(glob.glob("SEXTO SEMESTRE/Tema 1/**/*.vhd", recursive=True))

print(f"Total VHDL files in Tema 1: {len(files)}\n")

results = []
for f in files:
    # Run ghdl -a (with VHDL 93 / 08 / 1993 standard)
    # Let's test with both standard and default
    res = subprocess.run(["ghdl", "-a", "--std=93c", f], capture_output=True, text=True)
    success = (res.returncode == 0)
    results.append((f, success, res.stderr.strip(), res.stdout.strip()))
    status = "OK ✓" if success else "FAIL ✗"
    print(f"[{status}] {f}")
    if not success:
        print(f"       Error: {res.stderr.strip()}\n")

# Clean up GHDL work library files in sandbox
for cf in glob.glob("work-obj*.cf"):
    os.remove(cf)

