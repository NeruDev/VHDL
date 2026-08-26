import re
import os
import subprocess

files = sorted([f for f in os.listdir("Teoria") if f.endswith(".md") and f != "README.md"])

for fname in files:
    fpath = os.path.join("Teoria", fname)
    with open(fpath, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Extract blocks
    blocks = re.findall(r'```vhdl(.*?)```', content, re.DOTALL)
    print(f"\n==================== Checking {fname} ({len(blocks)} blocks) ====================")
    
    for i, b in enumerate(blocks):
        b_clean = b.strip()
        
        # Check if it has entity/architecture or is a snippet
        is_full = ("entity" in b_clean.lower() and "architecture" in b_clean.lower()) or ("package" in b_clean.lower())
        
        # If it's a full design, test with ghdl
        if is_full:
            test_file = f"sandbox/test_{fname[:-3]}_{i}.vhd"
            with open(test_file, "w", encoding="utf-8") as tf:
                tf.write(b_clean)
            
            res = subprocess.run(["ghdl", "-a", "--std=08", test_file], capture_output=True, text=True)
            if res.returncode == 0:
                print(f"  Block {i+1}: FULL ENTITY/PKG -> GHDL SYNTAX OK ✓")
            else:
                print(f"  Block {i+1}: FULL ENTITY/PKG -> GHDL ERROR ✗:\n{res.stderr.strip()[:300]}")
            # Clean up
            if os.path.exists(test_file):
                os.remove(test_file)
        else:
            print(f"  Block {i+1}: (Code snippet - declaration/statement)")

